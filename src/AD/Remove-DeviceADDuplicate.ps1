function Remove-DeviceADDuplicate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		[string]$ADDeviceRemovalCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message
	)

	begin {
		$msg = ""
	}
	process {
		try {
			#get ad Comp
			try {
				$ADComp = Get-ADComputer -Identity $buildInfo.AssetID -ErrorAction SilentlyContinue -Verbose:$VerbosePreference
				$ADComp.Name | Remove-ADDevice -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
			} catch {
				Write-Verbose "No device with name $($buildInfo.AssetID) exists in AD"
			}

		}
		catch {
			$msg = $DeviceDeploymentDefaultConfig.TicketInteraction.GeneralErrorMessage

			New-BuildProcessError -errorObj $_ -message "Rename Commands have Failed. To solve this, please manually check AD for any OLD AD-Computers with the same AssetID and remove them. Double check that you're not removing this device! Then manually rename the PC" -functionName "Remove-DeviceADDuplicate" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
			
		} finally {
			# add note to ticket that AD removal commands completed
			$buildInfo.buildState = $ADDeviceRemovalCompletionString
			Write-DeviceBuildTicket -buildInfo $buildInfo -message $msg -Verbose:$VerbosePreference
		}
		
	}
	end {
	}	
}