try {
    $gitUrl = "https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/" +
              "Git-1.9.5-preview20150319.exe"
    $gitInstallPath = "$ENV:Temp\git-installer.exe"

    # Download the git install at the correct location
    (New-Object System.Net.WebClient).DownloadFile($gitUrl, $gitInstallPath)

    #Run the git install in silent mode
    cmd.exe /C call $gitInstallPath /silent

    # Get OS version
    if([Environment]::Is64BitOperatingSystem -eq "True"){
      $addedFolder = "${env:ProgramFiles(x86)}\Git\cmd"
    }
    else {
      $addedFolder = "${env:ProgramFiles}\Git\cmd"
    }

    # The current environment path
    $pathParams = @{
        Path = 'Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment';
        Name = 'PATH'
    }

    # Get current environment path
    $oldPathParams = (Get-ItemProperty @$pathParams).Path

    # Create new environment path
    $newPath = Join-Path -Path $oldPath -ChildPath $addedFolder

    # Update the path parameters
    $pathParams.Add(Value, "$newPath")

    # Set the new environment path
    Set-ItemProperty @$pathParams
}
catch {
    Write-Warning "Git install failed"
    Write-Host $_
}
