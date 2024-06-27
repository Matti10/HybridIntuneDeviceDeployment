function Wait-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		$timeoutValue = $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("AssetID Mutex")) {
			try {
				$count = 0
				while ((Test-DeviceAssetIDMutex)) {
					if ($count -gt $timeoutValue) {
						Write-Error -Message "Testing Mutex has timed out `n" -ErrorAction Stop
					}

					Write-Verbose "Waiting on Mutex"
					Start-Sleep -Seconds 1
					$count += 1
				} 
			
				return Get-DeviceAssetIDMutex
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