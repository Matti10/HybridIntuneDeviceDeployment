function Select-DevicePendingCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$buildTicketData,
		
		[Parameter(Mandatory)]
		[string]$commandsPendingString,

		[Parameter(Mandatory)]
		[string]$commandsCompleteString
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$buildInfo = $buildTicketData.buildInfo
			$conversations = $buildTicketData.conversations

			$pending = $false
			
			$buildNotes = $conversations | Where-Object {$_.body -like "*$($buildInfo.GUID)*"}
			foreach ($buildNote in $buildNotes) {
				if ($buildNote.body -like "*$commandsCompleteString*") {
					# commands already completed
					$pending = $false
					return
				}

				if ($buildNote.body -like "*$commandsPendingString*") {
					$pending = $true
				}

			}

			if ($pending) {
				return $buildInfo
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