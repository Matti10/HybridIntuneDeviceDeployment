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