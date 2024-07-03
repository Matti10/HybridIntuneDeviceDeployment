function Get-PendingBuildTickets {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]
		$buildTicketFilter = $DeviceDeploymentDefaultConfig.TicketInteraction.ticketWaitingOnBuildFreshFilter
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($AssetID)) {
			try {

				$pendingTickets = @()

				$buildTickets = Get-FreshTickets -filter $buildTicketFilter

				foreach ($buildTicket in $buildTickets) {
					$conversations = Get-FreshTicketConversations -ticketID $buildTicket.ID

					if ($null -ne $conversations) {
						$buildGUID = Test-DeviceTicketCheckIn -conversations $conversations

						if ($buildGUID -ne $false) {
							$pendingTickets += @{
								TicketID = $buildTicketID
								BuildGUID = $buildGUID
							}
						}
					}
				}

				return $pendingTickets
			} 
			catch {
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}