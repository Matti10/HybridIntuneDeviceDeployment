
<#
.SYNOPSIS
This function will help to remove duplicates from Microsoft's Device Management System, Intune.

.DESCRIPTION
This function connects to the Intune API via the Connect-TriCareMgGraph command. 
It searches for any managed devices that have serial numbers matching the input parameter. 
If duplicate devices are found, the function removes those devices except for the latest one. Activity is logged to assist with debugging and error reporting.

.PARAMETER buildInfo
It is a mandatory parameter that takes input from the pipeline, which is an object containing device details. The serial number 
and intuneID from this object are used to find and remove duplicates.

.EXAMPLE
PS> Remove-DeviceIntuneDuplicateRecords -buildInfo $info

This would take a variable $info which contains all the hardware information and remove any duplicate managed devices.

.INPUTS
System.Management.Automation.PSCustomObject
#>

function Remove-DeviceIntuneDuplicateRecords {
    # Indicates that this cmdlet supports should process, which allows the cmdlet to prompt user before executing.
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # This is a mandatory parameter that takes input from the pipeline.
        # It should contain information about the device we want to check for duplicates
        [Parameter(Mandatory,ValueFromPipeline)]
        $buildInfo
    )

    # The begin block is where we establish the connection 
    begin {
        # Connects to the graph API
        Connect-TriCareMgGraph
    }
    # The process block is where we do the work
    process {
        try {
            # This will get all the devices managed by Intune with the same serial number as the provided device
            $duplicates = Get-MgDeviceManagementManagedDevice -Filter "serialNumber eq '$($buildInfo.serialNumber)'"
            # We then iterate through all the devices found
            foreach ($device in $duplicates) {
                # Looking for devices that are different from the one we are checking, based on their ID.
                if ($device.Id -ne $buildInfo.intuneID) {
                    # An output message for each device that is going to be removed
                    Write-Verbose "Removing $($device.ID)"
                    #Removing the duplicate managed device
                    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -whatif:$WhatIfPreference -verbose:$VerbosePreference -ErrorAction stop
                }
            }
        # In case something goes wrong, we handle the error here
        } catch {
            # We create a new error for the build process and pass along the error message
            New-BuildProcessError -errorObj $_ -message "Intune duplicate Cleanup has failed. Please search intune for any duplicate object with this devices serial number and manually delete any old objects." -functionName "Remove-DeviceIntuneDuplicateRecords" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
        }
    }
    # The end block is where we clean up
    end {
    }    
}