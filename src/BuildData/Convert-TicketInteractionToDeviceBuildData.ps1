

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
This function uses the ConvertFrom-HTMLTable cmdlet to convert HTML tables into PSCustomObjects. This function returns a custom object using the New-BuildInfoObj function, after being passed data obtained from the conversion process.

.LINK
Get-MyTicket
#>
function Convert-TicketInteractionToDeviceBuildData {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
    
        [Parameter(Mandatory,ValueFromPipeline)]
        [string]
        $text
        
    )

    # Initiate an empty array that will store any caught errors
    begin {
        $errorList = @()
    }
    process {
        # Check if the system should process the operation or not
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                # Convert the input HTML table into PSObject form 
                $raw = (ConvertFrom-HTMLTable -html $text)

                # Parse and trim group data to ensure valid inputs
                $groups = $raw.groups.split(",") | ForEach-Object {$_.Trim(" ")} | Where-Object {$_ -ne ""}

                # Return a new object containing build information
                return (New-BuildInfoObj -AssetID $raw.AssetID -hostname $raw.hostname -serialNumber $raw.serialNumber -type $raw.type -build $raw.build -ticketID $raw.ticketID -freshAsset $raw.freshAsset -OU $raw.OU -groups $groups -buildState $raw.buildState -guid $raw.guid -IntuneID $raw.IntuneID)
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
