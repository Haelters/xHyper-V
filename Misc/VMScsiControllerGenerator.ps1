New-xDscResource -Name MSFT_xVMScsiController -Path . -ClassVersion 1.0.0 -FriendlyName xVMScsiController -Property $(
    New-xDscResourceProperty -Name VmName -Type String -Attribute Read -Description "Name of the VM"
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present","Absent" -Description "Should the HardDiskDrive be attached or removed"
    New-xDscResourceProperty -Name ControllerNumber -Type Uint32 -Attribute Key -ValidateSet 0,1,2,3 -Description "The number of the controller"
)
