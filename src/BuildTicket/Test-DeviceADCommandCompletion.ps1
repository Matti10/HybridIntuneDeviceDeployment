function Test-DeviceADCommandCompletion {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$BuildInfo,
		


		[Parameter()]
		[string]$ADCommandCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("$($buildInfo)")) {				
				#--------------------------- Get All notes for the ticket  ---------------------------# 
				$conversations = Get-FreshTicketConversations -ticketID $BuildInfo.ticketID
				
				foreach ($conversation in $conversations) {
					if ("$($conversation)" -like "*$ADCommandCompletionString*$($BuildInfo.GUID)*") {
						return $true
					}
				}
				
				return $false
			}
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}