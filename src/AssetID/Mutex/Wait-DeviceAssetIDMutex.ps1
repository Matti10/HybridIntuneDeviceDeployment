function Wait-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

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
				while ((Test-DeviceAssetIDMutex -API_Key $API_Key)) {
					if ($count -gt $timeoutValue) {
						Write-Error -Message "Testing Mutex has timed out `n $mutex" -ErrorAction Stop
					}

					Start-Sleep -Seconds 1
					$count += 1
				} 
			
				return Get-DeviceAssetIDMutex -API_Key $API_Key
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