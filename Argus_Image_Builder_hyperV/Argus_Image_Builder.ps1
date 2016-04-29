try {
$isoPath = "..\en_windows_10_enterprise_x64_dvd_6851151.iso"

# Mount the ISO
$driveLetter = (Mount-DiskImage $isoPath -PassThru | Get-Volume).DriveLetter 
$wimFilePath = "${driveLetter}:\sources\install.wim"
 
Remove-Module WinImageBuilder
Import-Module "..\WinImageBuilder.psm1"
 
# Check what images are supported in this Windows ISO
$images = Get-WimFileImagesInfo -WimFilePath $wimFilePath
$images

# Get the Windows images available in the ISO 
$images | select ImageName
 
# Select the first one. Note: this will generate an image of Server Core.
# If you want a full GUI, or another image, choose from the list above
$image = $images[0]
 
$targetPath = "D:\windows_10_ENT_Argus_Updates.qcow2" 
 

New-WindowsOnlineImage -Type "KVM" -WimFilePath $wimFilePath -ImageName $image.ImageName `
-WindowsImagePath $targetPath -SizeBytes 30GB -Memory 4GB -InstallUpdates:$true `
-CpuCores 4 -DiskLayout "BIOS" -purgeUpdates:$true -RunSysprep -PersistDriverInstall:$true `
-VirtIOISOPath "..\virtio-win-0.1.117.iso"
} 


catch {
	Write-Warning "Image generation failed"
	Write-Host $_
} finally {
	Dismount-DiskImage $isoPath
}