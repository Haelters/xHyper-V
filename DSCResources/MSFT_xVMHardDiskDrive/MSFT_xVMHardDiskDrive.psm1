#region localizedData
if (Test-Path "${PSScriptRoot}\${PSUICulture}")
{
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xVMHardDiskDrive.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\${PSUICulture}"
}
else
{
    #fallback to en-US
    Import-LocalizedData `
        -BindingVariable LocalizedData `
        -Filename MSFT_xVMHardDiskDrive.strings.psd1 `
        -BaseDirectory "${PSScriptRoot}\en-US"
}
#endregion

#region targetResourceFunctions
<#
    .SYNOPSIS
    Returns the current status of the VM hard disk drive.
    .PARAMETER VMName
    Specifies the name of the virtual machine whose hard disk drive status is to be fetched.
    .PARAMETER Path
    Specifies the full path of the VHD file linked to the hard disk drive.
#>
function Get-TargetResource 
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VMName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    $hardDiskDrive = Get-VMHardDiskDrive -VMName $VMName -ErrorAction Stop | Where-Object { $_.Path -eq $Path } 

    $returnValue = @{
        VMName = $VMName
        Path = $Path
        ControllerType = if ($hardDiskDrive) {$hardDiskDrive.ControllerType} else {$null}
        ControllerNumber = if ($hardDiskDrive) {$hardDiskDrive.ControllerNumber} else {$null}
        ControllerLocation = if ($hardDiskDrive) {$hardDiskDrive.ControllerLocation} else {$null}
    }

    $returnValue
}

<#
    .SYNOPSIS
    Manipulates hard disk drives attached to a VM.
    .PARAMETER VMName
    Specifies the name of the virtual machine whose hard disk drive is to be manipulated.
    .PARAMETER Path
    Specifies the full path of the VHD file to be manipulated.
    .PARAMETER ControllerType
    Specifies the type of controller to which the the hard disk drive is to be set (IDE/SCSI).
    .PARAMETER ControllerNumber
    Specifies the number of the controller to which the hard disk drive is to be set. 
    If not specified, this parameter assumes the value of the first available controller at the location specified in the ControllerLocation parameter.
    .PARAMETER ControllerLocation
    Specifies the number of the location on the controller at which the hard disk drive is to be set. 
    If not specified, the first available location in the controller specified with the ControllerNumber parameter is used.
    .PARAMETER Ensure
    Specifies if the hard disk drive should exist or not.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VMName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [ValidateSet("IDE","SCSI")]
        [System.String]
        $ControllerType = "SCSI",

        [ValidateSet(0,1,2,3)]
        [System.UInt32]
        $ControllerNumber,

        [ValidateSet({return $_ -lt 64})]
        [System.UInt32]
        $ControllerLocation,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $hardDiskDrive = Get-VMHardDiskDrive -VMName $VMName | Where-Object { $_.Path -eq $Path } 

    if ($Ensure -eq "Present") 
    {
        $PSBoundParameters.Remove('Ensure')

        Write-Verbose ($localizedData.CheckingIfTheDiskIsAlreadyAttachedToTheVM)
        if ($hardDiskDrive) 
        {
            Write-Verbose ($localizedData.FoundDiskButWithWrongSettings)
            $PSBoundParameters.Remove('Path')
            # As the operation is a move, we must use ToController... instead of Controller...
            if ($PSBoundParameters.ContainsKey('ControllerType')) 
            {
                $PSBoundParameters.remove('ControllerType')
                $PSBoundParameters.Add('ToControllerType', $ControllerType)
            }
            if ($PSBoundParameters.ContainsKey('ControllerNumber')) 
            {
                $PSBoundParameters.Remove('ControllerNumber')
                $PSBoundParameters.Add('ToControllerNumber', $ControllerNumber)
            }
            if ($PSBoundParameters.ContainsKey('ControllerLocation')) 
            {
                $PSBoundParameters.Remove('ControllerLocation')
                $PSBoundParameters.Add('ToControllerLocation', $ControllerLocation)
            }
            $hardDiskDrive | Set-VMHardDiskDrive @PSBoundParameters 
            return
        }
        
        Write-Verbose ($localizedData.CheckingIfThereIsAnotherDiskOnThisLocation)
        $splatGetHardDiskDrive = @{
            VMName = $VMName 
            ControllerType = $ControllerType 
            ControllerNumber = $ControllerNumber 
            ControllerLocation = $ControllerLocation
        }
        $hardDiskDrive = Get-VMHardDiskDrive @splatGetHardDiskDrive
        if ($PSBoundParameters.ContainsKey('ControllerType') -and
            $PSBoundParameters.ContainsKey('ControllerNumber') -and
            $PSBoundParameters.ContainsKey('ControllerLocation') -and
            $hardDiskDrive -ne $null)
        {
            Write-Warning ($localizedData.ThereIsAnotherDiskOnThisLocation -f $hardDiskDrive.Path)
            $hardDiskDrive | Set-VMHardDiskDrive @PSBoundParameters -Path $Path 
            return
        }

        Write-Verbose ($localizedData.AddingTheDiskToTheFreeLocation)
        Add-VMHardDiskDrive @PSBoundParameters -Path $Path

    } 
    else # We must ensure that the disk is absent
    {
        if ($hardDiskDrive) 
        {
            Write-Verbose ($localizedData.RemovingVHDFromVM -f $Path)
            $hardDiskDrive | Remove-VMHardDiskDrive 
        }
        else 
        {
            Write-Warning $localizedData.CouldNotFindDiskToRemove
        }
    }
}

<#
    .SYNOPSIS
    Tests the state of a VM hard disk drive.
    .PARAMETER VMName
    Specifies the name of the virtual machine whose hard disk drive is to be tested.
    .PARAMETER Path
    Specifies the full path of the VHD file to be tested.
    .PARAMETER ControllerType
    Specifies the type of controller to which the the hard disk drive is to be set (IDE/SCSI).
    .PARAMETER ControllerNumber
    Specifies the number of the controller to which the hard disk drive is to be set. 
    If not specified, this parameter assumes the value of the first available controller at the location specified in the ControllerLocation parameter.
    .PARAMETER ControllerLocation
    Specifies the number of the location on the controller at which the hard disk drive is to be set. 
    If not specified, the first available location in the controller specified with the ControllerNumber parameter is used.
    .PARAMETER Ensure
    Specifies if the hard disk drive should exist or not.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VMName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [ValidateSet("IDE","SCSI")]
        [System.String]
        $ControllerType = "SCSI",

        [ValidateSet(0,1,2,3)]
        [System.UInt32]
        $ControllerNumber,

        [ValidateSet({return $_ -lt 64})]
        [System.UInt32]
        $ControllerLocation,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $PSBoundParameters.Remove('Ensure')
    $resource = Get-TargetResource @PSBoundParameters

    $result = $true
    foreach ($key in $resource.Keys)
    {
        $result = $result -and ($PSBoundParameters[$key] -eq $resource[$key])
    }

    return $result	
}
#endregion

Export-ModuleMember -Function *-TargetResource
