function Remove-DeviceADDuplicate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		[string]$ADDeviceRemovalCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message
	)

	begin {
	}
	process {
		try {
			#get ad Comp
			try {
				$ADComp = Get-ADComputer -Identity $buildInfo.AssetID -ErrorAction SilentlyContinue
				$ADComp.Name | Remove-ADDevice -WhatIf:$WhatIfPreference
			} catch {
				Write-Verbose "No device with name $($buildInfo.AssetID) exists in AD"
			}
			
			# add note to ticket that AD removal commands completed
			$buildInfo.buildState = $ADDeviceRemovalCompletionString
			Write-DeviceBuildTicket -buildInfo $buildInfo

		}
		catch {
			New-BuildProcessError -errorObj $_ -message "AD Commands have Failed for the above device. Please manually check that the device is in the listed OU and groups. This has not effected other parts of the build process." -functionName "Invoke-DeviceADCommands" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
		}
		
	}
	end {
	}	
}