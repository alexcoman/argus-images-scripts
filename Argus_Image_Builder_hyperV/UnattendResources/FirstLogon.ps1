$ErrorActionPreference = "Stop"
$resourcesDir = "$ENV:SystemDrive\UnattendResources"

try
{
	$Host.UI.RawUI.WindowTitle = "Setting Password Expiration To False For User CiAdmin"
    cmd /C wmic useraccount where "name='CiAdmin'" set PasswordExpires=FALSE
	
	$Host.UI.RawUI.WindowTitle = "Disabling uac"
    Set-ItemProperty -path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system" -name EnableLUA -value 0
}
catch
{
    $host.ui.WriteErrorLine($_.Exception.ToString())
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    # Prevents the setup from proceeding

    $logonScriptPath = "$resourcesDir\Logon.ps1"
    if ( Test-Path $logonScriptPath ) { del $logonScriptPath }
    throw
}
