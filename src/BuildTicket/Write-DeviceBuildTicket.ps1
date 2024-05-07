function Write-DeviceBuildTicket {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[System.Object]$BuildInfo,

		[Parameter()]
		[string]$message = "",

		[Parameter()]
		[string]$content = $DeviceDeploymentDefaultConfig.TicketInteraction.messageTemplate,

		[Parameter()]
		[string]$dateFormat = $DeviceDeploymentDefaultConfig.Generic.DefaultDateFormat,

		[Parameter()]
		$buildStates = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates,

		[Parameter(Mandatory)]
		[string]$API_Key
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$content = $content.replace("%TABLE%",(ConvertTo-HtmlTable -itemsList $BuildInfo))
			$content = $content.replace("%MESSAGE%", $message)
			$content = $content.replace("%TRACE%","Message sent by $(hostname) at $(Get-Date -Format $dateFormat)")
			
			#highlight status
			foreach ($cell in $content.split("<td>")) {
				foreach ($buildState in ($buildStates | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name) {
					if ($cell -like "*$($buildStates.$buildState.message)*") {
						$content = $content.replace("<td>$cell","<td style=`"background-color:$($buildStates.$buildState.color)`">$cell")
					}
				}
			}
			
			if ($PSCmdlet.ShouldProcess($BuildInfo.ticketID)) {
				New-FreshTicketNote -API_Key $API_Key -ticketID $BuildInfo.ticketID -content $content
			} else {
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