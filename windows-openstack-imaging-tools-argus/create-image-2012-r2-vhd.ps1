try {

    $ErrorActionPreference = "Stop"

    #Initial parameters configuration
    $vmName = "OpenStack WS 2012 R2 Standard Evaluation"
    $size = [uint64]"16" * 1GB
    $memory = [uint64]"2" * 1GB
    $processorNumber = [uint64]"2"
    $controllerType = [string]"IDE"
    $vmSwitch = "external"

    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $isoPath = "C:\ISO\9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVER_EVAL_EN-US-IRM_SSS_X64FREE_EN-US_DV5.ISO"
    $floppyPath = "$scriptPath\Autounattend.vfd"

    # Set the extension to VHD instead of VHDX only if you plan to deploy
    # this image on Grizzly or on Windows / Hyper-V Server 2008 R2
    $vhdPath = "C:\VM\windows-server-2012-r2.vhdx"

    # We want to start with a new VM
    $vm = Get-VM | where { $_.Name -eq "$vmName" }
    if ($vm) {
        if ($vm.State -eq "Running") {
            $vm | Stop-VM -Force
        }
        $vm | Remove-VM -Force
    }

    # We want to start with a new VHD/VHDX
    if (Test-Path "$vhdPath") {
        Remove-Item -Force "$vhdPath"
    }

    #Creating and configuring the VM
    Write-Host "Creating the VHD..."
    New-VHD "$vhdPath" -Dynamic -SizeBytes "$size"
    Write-Host "Creating the VM..."
    $vm = New-VM "$vmName" -MemoryStartupBytes "$memory"
    Write-Host "Setting the processor count..."
    $vm | Set-VM -ProcessorCount "$processorNumber"
    Write-Host "Attaching the network adapter..."
    $vm.NetworkAdapters | Connect-VMNetworkAdapter -SwitchName "$vmSwitch"
    Write-Host "Attaching the VHD/VHDX to the vm..."
    $vm | Add-VMHardDiskDrive -ControllerType $controllerType -Path "$vhdPath"
    Write-Host "Attaching the ISO to the vm..."
    $vm | Add-VMDvdDrive -Path "$isoPath"
    Write-Host "Attaching the floppy disk to the vm..."
    $vm | Set-VMFloppyDiskDrive -Path "$floppyPath"

    #Starting the VM
    Write-Host "Starting the vm..."
    $vm | Start-Vm
}
catch {
    Write-Warning "The Image creation has falled"
    Write-Host $_
}
