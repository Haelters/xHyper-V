New-xDscResource -Name MSFT_xVMHardDiskDrive -Path . -ClassVersion 1.0.0 -FriendlyName xVMHardDiskDrive -Property $(
    New-xDscResourceProperty -Name VmName -Type String -Attribute Read -Description "Name of the VM"
    New-xDscResourceProperty -Name VhdPath -Type String -Attribute Key -Description "Folder where the VHD is located"
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent" -Description "Should the HardDiskDrive be attached or removed"
    New-xDscResourceProperty -Name ControllerType -Type String -Attribute Write -ValidateSet "IDE","SCSI" -Description "The controller type - IDE/SCSI to use for the disk"
    New-xDscResourceProperty -Name ControllerNumber -Type Uint32 -Attribute Write -ValidateSet 0,1,2,3 -Description "The number of the controller to use for the disk"
    New-xDscResourceProperty -Name ControllerLocation -Type Uint32 -Attribute Read -Description "The location of the drive on the controller"
)
