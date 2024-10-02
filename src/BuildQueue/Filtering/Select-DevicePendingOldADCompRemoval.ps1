
<#

This PowerShell function selects active directory devices that are pending for old component removal.

.SYNOPSIS
Executes a process to determine pending/ongoing Active Directory (AD) device removals based on the given build ticket data, and completes when a certain condition is met.

.DESCRIPTION
The `Select-DevicePendingOldADCompRemoval` function processes a given set of build ticket data passed via pipeline or through the `$buildTicketData` parameter and checks the status of old AD components pending for removal. The function returns data on devices that are in the process of removing old components.



.PARAMETER -buildTicketData
([System.Object]) (mandatory)
This parameter represents the data associated with build tickets. You must specify a value for this parameter. Values are accepted from pipeline.

.PARAMETER -ADDeviceRemovalPendingString
([string])
This string parameter indicates the status of an AD device removal that is pending. The default value is obtained from the message indicating the state of an old active directory object pending for removal.

.PARAMETER -ADDeviceRemovalCompletionString
([string])
This string parameter indicates the status of an AD device removal that has been completed. The default value is obtained from the message indicating the completion state of an old active directory object removal.

.EXAMPLE

# Example: Providing build ticket data via parameter
$buildData = Get-BuildTicketData
Select-DevicePendingOldADCompRemoval -buildTicketData $buildData

# Example: Using pipeline to provide build ticket data
Get-BuildTicketData | Select-DevicePendingOldADCompRemoval


.NOTES
In your environment, replace `$DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalPendingState.message` with the actual value indicating the pending state of old AD component removal in your system configuration. Similarly, replace `$DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message` with the actual value indicating the completed state of old AD component removal in your system. 

Function's execution flow consists of three main parts:

1. `begin`: Initializes empty arrays `$errorList` and `$allBuildTicketData`.
2. `process`: Collects data from the pipeline into the `$allBuildTicketData` array and catches any exceptions.
3. `end`: Sends all collected data through the `Select-DevicePendingCommands` function, catches any exceptions, and stops execution if any error occurs. 

### ERROR HANDLING
This function comes with built-in error handling that captures any exceptions during the data collection or removal process and writes it to the PowerShell error stream. If any error(s) occur, it will stop the function execution and display an error message with the call stack for debugging. 

This function supports "ShouldProcess", a feature that allows you to verify whether the function will make any changes before executing it.

#>
function Select-DevicePendingOldADCompRemoval {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$buildTicketData,
		
		[Parameter()]
		[string]$ADDeviceRemovalPendingString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalPendingState.message,

		[Parameter()]
		[string]$ADDeviceRemovalCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message
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
			return ($allBuildTicketData | Select-DevicePendingCommands -commandsPendingString $ADDeviceRemovalPendingString -commandsCompleteString $ADDeviceRemovalCompletionString)
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