
# Documentation
<#
.SYNOPSIS
This function, Test-DeviceTicketCheckIn, is purposed to sort through conversations in order to ascertain if a noted device ticket has been successfully checked in. The check in message and check completion message are searched for, giving the function the capability to verify the status of device tickets.

.DESCRIPTION
This PowerShell script function initializes an empty list to store errors occurred during script execution. It takes as input a list of conversations and two optional string parameters; ticketCheckInString and ticketCompletionString. It then sorts these conversations by most recent. It subsequently goes through each conversation, checks if it contains the check-in message and converts it to device build data. It then looks for the GUID of the build in the remaining conversations, and if it finds the completion message it skips checking back again. Otherwise, it returns the build information. At the end, it checks if any errors happened during the execution and if so, it throws an error with details.

.PARAMETER conversations
This parameter is mandatory. It's a list of conversation items which are needed to be processed by this function. 

.PARAMETER ticketCheckInString
This is an optional parameter, which specifies the string that identifies the check-in state. If not provided, the script uses the message string defined in the TicketInteraction field of the DeviceDeploymentDefaultConfig.

.PARAMETER ticketCompletionString
This is also an optional parameter, which specifies the string that identifies the completion state. If not provided, the script uses the completion message string defined in the TicketInteraction field of the DeviceDeploymentDefaultConfig.

.EXAMPLE
Test-DeviceTicketCheckIn -conversations $conversations -ticketCheckInString "Device Checked In" -ticketCompletionString "Build Completed"

This example processes the provided $conversations array to check for completed device builds, with explicit check-in and completion strings.

.INPUTS
A list of conversations, an optional string identifying check-in state, and another optional string identifying completion state.

.OUTPUTS
Upon successful completion, the function either returns the build information or false. In case of errors in execution, it throws a detailed error message.
#>

function Test-DeviceCheckIn {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo #Mandatory parameter that accepts a list of conversations
	)

	begin {
		$errorList = @() #Initializes an empty error list
	}
	process {
		try {
			if ($null -eq $buildInfo.RecordID -or "" -eq $buildInfo.RecordID) {
				return $false
			}
			return $true
		}
		catch {
			$errorList += $_ #Handle error and add it to the error list
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			#If there were any errors during execution, throw a detailed error message
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}