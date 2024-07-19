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