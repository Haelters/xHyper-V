configuration Sample_xVMHardDiskDrive
{
    param
    (
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$VMName,
        
        [Parameter(Mandatory)]
        [string]$VhdPath,   
        
        [Parameter(Mandatory)]
        [string]$ControllerNumber
    )

    Import-DscResource -ModuleName 'xHyper-V'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $NodeName
    {
        # Install HyperV feature, if not installed - Server SKU only
        $diskNameOS = "$VMName-DiskOS.vhdx"
        $diskNameExtra1 = "$VMName-Disk1.vhdx"

        WindowsFeature HyperV
        {
            Ensure = 'Present'
            Name   = 'Hyper-V'
        }

        xVHD DiskOS
        {
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]HyperV'
            Name = $diskNameOS
            Path = $VhdPath
            Generation = 'vhdx'
            MaximumSizeBytes = 20GB
        }

        xVHD Disk1
        {
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]HyperV'
            Name = $diskNameExtra1
            Path = $VhdPath
            Generation = 'vhdx'
            MaximumSizeBytes = 20GB
        }

        xVMHyperV NewVM
        {
            Ensure     = 'Present'
            Name       = $VMName
            VhdPath    = Join-Path $VhdPath -ChildPath $diskNameOS
            Generation = 1
            DependsOn  = '[xVHD]DiskOS'
        }

        # Ensures a VM with default settings
        xVMScsiController Controller
        {
            Ensure           = 'Present'
            VMName           = $VMName
            ControllerNumber = $ControllerNumber
            DependsOn        = '[xVMHyperV]NewVM'
        }

        xVMHardDiskDrive ExtraDisk
        {
            VMName = $VMName
            Path = Join-Path $VhdPath -ChildPath $diskNameExtra1
            ControllerLocation = $ControllerLocation
            ControllerNumber = $ControllerNumber
            Ensure = 'Present'
            DependsOn = '[xVMScsiController]Controller', '[xVHD]Disk1'
        }
    }
}

$mofPath = "C:\temp\Sample_xVMHardDiskDrive"

Sample_xVMHardDiskDrive -VMName test1 -VhdPath C:\temp\Tests -ControllerNumber 2 -OutputPath $mofPath 
Start-DscConfiguration -Path $mofPath -Verbose -Wait -Force
