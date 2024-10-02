
<#

.SYNOPSIS
This function selects devices that have pending Active Directory (AD) commands.

.DESCRIPTION
Select-DevicePendingADCommands is used to select devices based on their pending AD commands. It will get every device that came in through the pipeline and forward them to the Select-DevicePendingCommands function with the configured pending and completed string messages for the AD commands. In case of any errors in the pipeline, the function will catch the exceptions and print them. All the error messages generated during the processing are stored in `$errorList` variable which are ultimately printed when the function ends.


.PARAMETER buildTicketData 
([System.Object], Mandatory): This object is used as the data input that is passed to the function through the pipeline.
.PARAMETER ADCommandPendingString 
([string]): This is the string used to determine the pending state of an AD command. The default value is fetched from `$DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adPendingState.message`.
.PARAMETER ADCommandCompletionString 
([string]): This is the string used to determine the completion state of an AD command. The default value is fetched from `$DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message`.

.EXAMPLE
Apply function on an array of ticket data

$ticketDataObjects | Select-DevicePendingADCommands


This will select devices with pending AD commands from an array of ticket data objects and pass them to Select-DevicePendingCommands function using the configured AD command pending and completion statuses.

.NOTES
- Both `$ADCommandPendingString` and `$ADCommandCompletionString` use the default configuration from `$DeviceDeploymentDefaultConfig`. If you want to use different strings, you can set these parameters manually.
- This function uses exception handling (`try-catch`) blocks to identify and handle any errors that occur during execution. These errors are captured and displayed through `Write-Error` at the end of the function. If multiple errors occur, they are appended to the `$errorList` array and displayed collectively at the end.
- This function supports pipeline input, whereby it can accept and process multiple device entries at a time for efficiency.
- If any errors occur during the function execution, it outputs the full PowerShell call stack along with the error messages to offer a detailed context for debugging.

#>

function Select-DevicePendingADCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$buildTicketData,
		
		[Parameter()]
		[string]$ADCommandPendingString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adPendingState.message,

		[Parameter()]
		[string]$ADCommandCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message
	)

	begin {
		$errorList = @()
		$allBuildTicketData = @()
	}
	process {
		try {
			#collect all data from pipeline
			$allBuildTicketData += $buildTicketData
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		try {
			# pass data through main filter function
			return ($allBuildTicketData | Select-DevicePendingCommands -commandsPendingString $ADCommandPendingString -commandsCompleteString $ADCommandCompletionString)
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}