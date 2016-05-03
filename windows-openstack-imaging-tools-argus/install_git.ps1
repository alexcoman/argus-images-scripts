$GitUrl = ("https://github.com/msysgit/msysgit/releases/download/Git-1.9.5-preview20150319/Git-1.9.5-" +
           "preview20150319.exe")
$GitInstallPath = "$ENV:Temp\git-installer.exe"
(new-object System.Net.WebClient).DownloadFile($GitUrl, $GitInstallPath)
cmd.exe /C call $GitInstallPath /silent
if([Environment]::Is64BitOperatingSystem -eq "True"){
  $AddedFolder = "${env:ProgramFiles(x86)}\Git\cmd"
} else {
  $AddedFolder = "${env:ProgramFiles}\Git\cmd"
}
$OldPath = (Get-ItemProperty -Path `
           'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' `
           -Name PATH).Path
$NewPath = $OldPath + ";" + $AddedFolder
Set-ItemProperty -Path `
    'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' `
    -Name PATH -Value $NewPath
