

<#
.SYNOPSIS
Converts the data from a ticket interaction into the format used for device build information.

.DESCRIPTION
The Convert-TicketInteractionToDeviceBuildData function is used within a PowerShell script to interact with text inputs. This function will convert the data from a ticket interaction into the format used for device build information. It handles the conversion process and also includes logging for any errors that come up during processing. 

.PARAMETER text
(Mandatory): This input string contains the data that needs to be converted.

.EXAMPLE
Convert-TicketInteractionToDeviceBuildData -text $exampleText

.INPUTS
String

.OUTPUTS
Object

.NOTES

.LINK
Get-MyTicket
#>
function Convert-BuildQueueToBuildData {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        $record,

        [Parameter()]
        $freshRecordIDAttr = $DeviceDeploymentDefaultConfig.BuildQueue.freshRecordIDAttr,

        [Parameter()]
        $excludedFreshAttrs = $DeviceDeploymentDefaultConfig.BuildQueue.excludedFreshAttrs,

        [Parameter()]
		$listDisplayDelimiter = $DeviceDeploymentDefaultConfig.TicketInteraction.listDisplayDelimiter
    )

    # Initiate an empty array that will store any caught errors
    begin {
        $errorList = @()
    }
    process {
        # Check if the system should process the operation or not
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                if ("" -eq $record.recordID -or $null -eq $record.recordID) {
                    $record.recordID = $record.$freshRecordIDAttr
                }

                $record.groups = $record.groups.split($listDisplayDelimiter)

                return $record | Select-Object -ExcludeProperty $excludedFreshAttrs
            }
            catch {
                # Catch and record any errors while executing the function
                $errorList += $_
                Write-Error $_
            }
        }
    }
    end {
        # Throw an error if there are any in the error list
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }   
}
