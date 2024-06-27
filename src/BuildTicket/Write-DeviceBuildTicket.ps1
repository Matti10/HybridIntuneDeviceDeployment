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
		$formattingConfig = $DeviceDeploymentDefaultConfig.TicketInteraction.freshFormatting
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$tempBuildInfo = $BuildInfo
			$tempBuildInfo.freshAsset = $tempBuildInfo.freshAsset.asset_tag
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
			
			if ($PSCmdlet.ShouldProcess($BuildInfo.ticketID)) {
				New-FreshTicketNote -ticketID $BuildInfo.ticketID -content $content
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