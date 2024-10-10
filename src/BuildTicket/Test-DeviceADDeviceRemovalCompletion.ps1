
# Documentation
<#
.SYNOPSIS
The Test-DeviceADDeviceRemovalCompletion function is used to verify if the Active Directory device removal process has been completed for a specified ticket. The complete status of the removal is noted in the ticket conversation.

.DESCRIPTION
This function takes in parameters BuildInfo (mandatory) and an optional ADDeviceRemovalCompletionString which is generally a string message retrieved from the Device Deployment Default Configuration.

It begins by initializing an empty error list. During the process, it retrieves all conversations for a specific ticket. It then verifies if the Active Directory device removal has been completed by checking if the ADDeviceRemovalCompletionString along with the Global Unique Identifier (GUID) are mentioned in the ticket conversations. 

If they are found, it returns true, signifying that the removal process is complete. Otherwise, it returns false.

Any errors that occur during the process are captured and written to the errorList.

At the end, if any errors exist in the error list, they are reported along with the function call stack information, and the function is stopped.

.PARAMETER BuildInfo
This mandatory parameter represents information about a specific ticket. It is piped as input and is expected to be of System.Object type.

.PARAMETER ADDeviceRemovalCompletionString
This parameter, although optional, is important as it is the string used to signify that the AD device removal process has been completed. By default, the value of this parameter is the specific message from the DeviceDeploymentDefaultConfig configuration.

.NOTES
Any exceptions that occur are written to the errorList and are reported at the end of the function execution.

.EXAMPLE
Test-DeviceADDeviceRemovalCompletion -BuildInfo $TicketInformation

Checks if the AD Device has been removed for the provided ticket information, and returns true if it has been removed, and false otherwise. IEnumerable<Conversations> 

#>
function Test-DeviceADDeviceRemovalCompletion {
	# CmdletBinding with SupportsShouldProcess enabled
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Mandatory parameter that accepts pipeline input
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$BuildInfo,

		# Optional parameter task status message
		[Parameter()]
		[string]$ADDeviceRemovalCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message
	)

	# Begin block where we initialize error list
	begin {
		$errorList = @()
	}
	# Process block where main action of function is performed
	process {
		try {
			# Fetch all conversations for the ticket  
			$conversations = Get-FreshTicketConversations -recordID $BuildInfo.recordID

			# Check each conversation to see if AD Device Removal has been completed
			foreach ($conversation in $conversations) {
				if ("$($conversation)" -like "*$ADDeviceRemovalCompletionString*$($BuildInfo.GUID)*") {
					# If found, return true
					return $true
				}
			}

			#If not found, return false
			return $false
		}
		catch {
			#Catch and record errors
			$errorList += $_
			Write-Error $_
		}
	}
	# In the end block, if there were errors, stop the function and report the errors
	end {
		# If an error was caught, stop the function and print the error
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}