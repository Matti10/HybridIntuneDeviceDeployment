function Remove-DeviceADDuplicate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		[string]$ADDeviceRemovalCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message
	)

	begin {
		$errorList = @()
	}
	process {
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
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}