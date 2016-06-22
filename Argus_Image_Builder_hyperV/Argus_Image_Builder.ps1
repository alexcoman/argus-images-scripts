try {

    # Started parameters configuration
    $workDir = "C:\Users\work\Desktop"
    $isoName = "en_windows_10_enterprise_x64_dvd_6851151"
    $virtISO = "virtio-win-0.1.117.iso"
    $targetName = "windows_10_2.qcow2"

    # Creating the important paths
    $isoPath = Join-Path -Path "$workDir" -ChildPath "$isoName"
    $targetPath = Join-Path -Path "$workDir" -ChildPath "$targetName"
    $virtISOPath = Join-Path -Path "$workDir" -ChildPath "$virtISO"

    # Mount the ISO and map the correct WIM file
    $driveLetter = (Mount-DiskImage $isoPath -PassThru | Get-Volume).DriveLetter
    $wimFilePath = "${driveLetter}:\sources\install.wim"

    # We are removing the module only if it's present. If this script will be used in Jenkins or
    # a system where the ErrorPreference will be Stop, the job will fail
    if (Get-Module WinImageBuilder) {
        Remove-Module WinImageBuilder
    }
    Import-Module "C:\Users\work\Desktop\argus-images-scripts\Argus_Image_Builder_hyperV\WinImageBuilder.psm1"

    # Check what images are supported in this Windows ISO
    $images = Get-WimFileImagesInfo -WimFilePath $wimFilePath

    # Get the Windows images available in the ISO
    $images | select ImageName

    # Here we are selecting the type of image we want to generate.
    # For 2012R2: [0] is ServerCore(no GUI) and [1] is ServerStandard (With GUI)
    # For 2008R2: [0] is ServerStandard(With GUI) and [1] is ServerCore(No GUI)

    $image = $images[0]
    $image = $image.ImageName

    $NewWindowsOnlineImageParams = @{
        Type = [string]"KVM";
        WimFilePath = [string]"$wimFilePath";
        ImageName = [string]"$image";
        WindowsImagePath = [string]"$targetPath";
        VirtIOISOPath = [string]"$virtISOPath";
        DiskLayout = [string]"BIOS";
        SizeBytes = [uint64]"30" * 1GB;
        Memory = [uint64]"2" * 1GB;
        CpuCores = [uint64]"4";
        RunSysprep = [bool]'$true';
        InstallUpdates = [bool]'$true';
        PurgeUpdate = [bool]'$true';
        PersistDriverInstall = [bool]'$false';
    }

    New-WindowsOnlineImage @NewWindowsOnlineImageParams

}

catch {
    Write-Warning "Image generation failed"
    Write-Host $_
} finally {
    Dismount-DiskImage $isoPath
}

