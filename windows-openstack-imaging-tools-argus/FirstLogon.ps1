$ErrorActionPreference = "Stop"

function getOSVersion(){
    $v = (Get-WmiObject Win32_OperatingSystem).Version.Split('.')
    return New-Object psobject -Property @{
        Major = [int]::Parse($v[0])
        Minor = [int]::Parse($v[1])
        Build = [int]::Parse($v[2])
    }
}
function Install-VirtIODrivers()
{
    $Host.UI.RawUI.WindowTitle = "Downloading VirtIO certificate..."
    $virtioCertPath = "$ENV:SystemRoot\Temp\VirtIO.cer"
    $url = "$baseUrl/VirtIO.cer"
    (new-object System.Net.WebClient).DownloadFile($url, $virtioCertPath)

    $Host.UI.RawUI.WindowTitle = "Installing VirtIO certificate..."
    $cacert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($virtioCertPath)
    $castore = New-Object System.Security.Cryptography.X509Certificates.X509Store([System.Security.Cryptography.X509Certificates.StoreName]::TrustedPublisher,`
                     [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
    $castore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
    $castore.Add($cacert)

    #$driversBasePath = (Get-WMIObject Win32_CDROMDrive | ? { $_.caption -like "*virt*" }).Drive
    $driversBasePath = "E:"
    $windowsVersion = getOSVersion
    if([Environment]::Is64BitOperatingSystem -eq "True"){
      $windowsArchitecure = "amd64"
    } else {
      $windowsArchitecure = "x86"
    }
    # For VirtIO ISO with drivers version lower than 1.8.x
    if ($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -eq 0) {
        $virtioVer = "VISTA"
    } elseif ($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -eq 1) {
        $virtioVer = "WIN7"
    } elseif (($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -ge 2) `
        -or $windowsVersion.Major -gt 6) {
        $virtioVer = "WIN8"
    } else {
        throw "Unsupported Windows version for VirtIO drivers"
    }
    # For VirtIO ISO with drivers version higher than 1.8.x
    $windowsType = (Get-WmiObject win32_operatingsystem).producttype
    if ($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -eq 0) {
        $virtioVer = "2k8"
    } elseif ($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -eq 1) {
        if ($windowsType -eq "3") {
            $virtioVer = "2k8r2"
        } else {
            $virtioVer = "w7"
        }
    } elseif ($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -eq 2) {
        if ($windowsType -eq "3") {
            $virtioVer = "2k12"
        } else {
            $virtioVer = "w8"
        }
    } elseif (($windowsVersion.Major -eq 6 -and $windowsVersion.Minor -ge 3) `
        -or $windowsVersion.Major -gt 6) {
        if ($windowsType -eq "3") {
            $virtioVer = "2k12R2"
        } else {
            $virtioVer = "w8.1"
        }
    } elseif(($windowsVersion.Major -eq 10)) {
        $virtioVer = "w10"
    } else {
        throw "Unsupported Windows version for VirtIO drivers"
    }
    $drivers = @("Balloon", "NetKVM", "viorng", "vioscsi", "vioserial", "viostor")
    foreach ($driver in $drivers) {
        $virtioDir = "{0}\{1}\{2}\{3}" -f $driversBasePath, $driver, $virtioVer, $windowsArchitecure
        pnputil.exe -i -a $virtioDir\*.inf
    }
}

function getHypervisor() {
    $checkHypervisorExeUrl = "https://github.com/cloudbase/checkhypervisor/raw/master/bin/checkhypervisor.exe"
    $checkHypervisorExePath = "$ENV:SystemRoot\Temp\checkhypervisor.exe"
    Invoke-WebRequest -Uri $checkHypervisorExeUrl -OutFile $checkHypervisorExePath

    $hypervisor = & $checkHypervisorExePath

    if ($LastExitCode -eq 1) {
        Write-Host "No hypervisor detected."
    } else {
        return $hypervisor
    }
}

$logonScriptPath = "$ENV:SystemRoot\Temp\Logon.ps1"

try
{
    $Host.UI.RawUI.WindowTitle = "Setting Password Expiration To False For User CiAdmin"
    cmd /C wmic useraccount where "name='CiAdmin'" set PasswordExpires=FALSE
    # Disable UAC so that using /runas for Start-Process will work.
    # Also, it will require a reboot and since Logon.ps1 runs after
    # we restart, we add this modifier here.
    $Host.UI.RawUI.WindowTitle = "Disabling uac"
    Set-ItemProperty -path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system" -name EnableLUA -value 0

    $Host.UI.RawUI.WindowTitle = "Downloading Logon script..."
    $baseUrl = "https://raw.github.com/stefan-caraiman/windows-openstack-imaging-tools/master"
    (new-object System.Net.WebClient).DownloadFile("$baseUrl/Logon.ps1", $logonScriptPath)

    $hypervisorStr = getHypervisor
    Write-Host "Hypervisor: $hypervisorStr"
    # TODO: Add XenServer / XCP
    switch($hypervisorStr)
    {
        "VMwareVMware"
        {
            # Note: this command will generate a reboot.
            # "/qn REBOOT=ReallySuppress" does not seem to work properly
            $Host.UI.RawUI.WindowTitle = "Installing VMware tools..."
            E:\setup64.exe `/s `/v `/qn `/l `"$ENV:SystemRoot\Temp\vmware_tools_install.log`"
            if (!$?) { throw "VMware tools setup failed" }
        }
        "KVMKVMKVM"
        {
            Install-VirtIODrivers
            Start-Sleep -s 10
            shutdown /r /t 0
        }
    }
}
catch
{
    #$host.ui.WriteErrorLine($_.Exception.ToString())
    #$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    # Prevents the setup from proceeding
    if ( Test-Path $logonScriptPath ) { del $logonScriptPath }
    throw
    Start-Sleep -s 15
}

