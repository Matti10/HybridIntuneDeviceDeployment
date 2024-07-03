function Test-DeviceTicketCheckIn {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		$conversations,

		[Parameter()]
		[string]$ticketCheckInString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.checkInState.message,

		[Parameter()]
		[string]$ticketCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.completedState.message
	)

	begin {
		$errorList = @()
	}
	process {
		try {

			#sort newest to oldest 
			$conversations = $conversations | Sort-Object updated_at -Descending

			:mainConversationLoop foreach ($conversation in $conversations) {
				#test if this note/reply is a ticket check in
				if ("$($conversation)" -like "*$ticketCheckInString*") {
					$buildInfo = Convert-TicketInteractionToDeviceBuildData -text $conversation.body

					#test if the build associated with the check in is completed
					foreach ($laterConversation in $conversations | ? {$_.body -like "*$buildInfo*"}) {
						if ("$($laterConversation)" -like "*$ticketCompletionString*") {
							Continue :mainConversationLoop
						}
					}
					
					return 
				}
			}

			return $false
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