function Get-PendingBuildTickets {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]
		$buildTicketStatusFilter = $DeviceDeploymentDefaultConfig.TicketInteraction.ticketWaitingOnBuildFreshFilter
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("")) {
			try {

				$pendingTickets = @()

				$buildTickets = Get-FreshTickets -filter $buildTicketStatusFilter | Select-ValidBuildTickets


				foreach ($buildTicket in $buildTickets) {
					$conversations = Get-FreshTicketConversations -ticketID $buildTicket.ID

					if ($null -ne $conversations) {
						$buildInfo = Test-DeviceTicketCheckIn -conversations $conversations

						if ($buildInfo -ne $false) {
							$pendingTickets += @{
								buildInfo = $buildInfo
								conversations = $conversations
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