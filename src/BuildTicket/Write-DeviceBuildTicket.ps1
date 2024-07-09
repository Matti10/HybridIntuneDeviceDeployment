function Write-DeviceBuildTicket {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$BuildInfo,

		[Parameter()]
		[string]$message = "",

		[Parameter()]
		[string]$content = $DeviceDeploymentDefaultConfig.TicketInteraction.messageTemplate,

		[Parameter()]
		[string]$dateFormat = $DeviceDeploymentDefaultConfig.Generic.DefaultDateFormat,

		[Parameter()]
		$buildStates = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates,

		[Parameter()]
		$formattingConfig = $DeviceDeploymentDefaultConfig.TicketInteraction.freshFormatting,
		
		[Parameter()]
		$listDisplayDelimiter = $DeviceDeploymentDefaultConfig.TicketInteraction.listDisplayDelimiter
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$tempBuildInfo = [PSCustomObject]@{}
			#copy values into a temp object (BECAUSE POWERSHELL CANT NOT PASS BY REFERENCE!!!!!!!!)
			$BuildInfo | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} | ForEach-Object {
				$tempBuildInfo | Add-Member -MemberType NoteProperty -Name $_.Name -Value $BuildInfo."$($_.Name)"
			}

			# convert the list of groups to a readable format
			$tempBuildInfo.groups = ""
			foreach ($group in $BuildInfo.groups) {
				$tempBuildInfo.groups = "$group$listDisplayDelimiter$($tempBuildInfo.groups)"
			}
			$tempBuildInfo.groups = $tempBuildInfo.groups.TrimEnd(", ")

			# change fresh asset object to its asset id
			try {
				$tempBuildInfo.freshAsset = $tempBuildInfo.freshAsset.asset_tag
			} catch {
				#do nothing - the fresh asset feild is already the fresh asset tag (rather than a fresh asset object)
			}

			$content = $content.replace("%TABLE%", (ConvertTo-HtmlTable -itemsList $tempBuildInfo -vertical))
			$content = $content.replace("%MESSAGE%", $message)
			$content = $content.replace("%TRACE%", "Message sent by $(hostname) at $(Get-Date -Format $dateFormat)")
			

			#find the current build state
			$buildState = $buildStates.initialState
			foreach ($state in ($buildStates | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" }).Name) {
				if ($content -like "*$($buildStates.$state.message)*") {
					$buildState = $buildStates.$state
				}
			}

			#do some formatting
			foreach ($element in $formattingConfig) {
				$content = $content -replace "<$($element.name)>", "<$($element.name) style=`"$($element.format)`">"
				$content = $content -replace "%BGCOLOR%", "$($buildState.color)"
			}
			
			if ($PSCmdlet.ShouldProcess("Ticket: $($BuildInfo.ticketID) State: $($buildState)")) {
				New-FreshTicketNote -ticketID $BuildInfo.ticketID -content $content | Out-Null
			}
			else {
				return $content
			}
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}