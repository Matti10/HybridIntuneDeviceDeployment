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

			:mainConversationLoop foreach ($conversation in $conversations | Where-Object {$_.body -like "*$ticketCheckInString*"}) {
				#test if this note/reply is a ticket check in
				$buildInfo = Convert-TicketInteractionToDeviceBuildData -text $conversation.body

				#test if the build associated with the check in is completed
				foreach ($laterConversation in $conversations | Where-Object {$_.body -like "*$($buildInfo.GUID)*"}) {
					if ("$($laterConversation)" -like "*$ticketCompletionString*") {
						Continue mainConversationLoop
					}
				}
				
				return $buildInfo
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