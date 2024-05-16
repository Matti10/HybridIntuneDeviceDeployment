function Unprotect-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter(Mandatory)]
		$mutex
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("Device Asset ID Mutex")) {
			try {
				$remoteMutex = Get-DeviceAssetIDMutex -API_Key $API_Key

				if ($remoteMutex.setBy -eq $mutex.setBy) {
					$mutex.currentlyaccessed = $false
					return Set-DeviceAssetIDMutex -API_Key $API_Key -mutex $mutex
				} else {
					Write-Error "Unable to unproctect mutex as it was set by a different actor `n $mutex"
				}
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