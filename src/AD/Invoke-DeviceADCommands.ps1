function Invoke-DeviceADCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		$ADCommandsCompletedString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message
	)

	begin {
		$errorList = @()
	}
	process {
		#get ad Comp
		try {
			$ADComp = Get-ADComputer -Identity $buildInfo.AssetID
		} catch {
			# if comp cant be found using asset id, try with hostname (lest rename fails)
			try {
				$ADComp = Get-ADComputer -Identity $buildInfo.hostname
			} catch {
				Write-Error "Computer with AssetID/Hostname $($buildInfo.AssetID)/$($buildInfo.hostname) doesn't exist in AD" -ErrorAction stop
			}
		}

		# add to groups
		foreach ($group in $buildInfo.groups) {
			Write-Verbose "Adding $($ADComp.SamAccountName) to $group"
			Add-ADGroupMember -Identity $group -Members $ADComp.SamAccountName -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
		}

		# move to correct OU
		Write-Verbose "Moving $($ADComp.SamAccountName) to $($buildInfo.OU)"
		Move-ADObject -Identity $ADComp.DistinguishedName -TargetPath $buildInfo.OU -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference

		# add note to ticket that AD commands completed
		$buildInfo.buildState = $ADCommandsCompletedString
		Write-DeviceBuildTicket -buildInfo $buildInfo

	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}