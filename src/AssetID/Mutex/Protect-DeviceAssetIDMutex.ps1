function Protect-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter()]
		$recursionCounter = 0,

		[Parameter()]
		$timeoutValue = $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds,

		[Parameter()]
		$UID = "$(hostname)-$((Get-Date).ToFileTime())",

		[Parameter()]
		$resetValue = $DeviceDeploymentDefaultConfig.AssetID.resetValue
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($UID)) {
			try {
				if ($recursionCounter -gt ($timeoutValue/4)){
					Write-Error "Protecting Mutex has timed out.`n$mutex" -ErrorAction Stop
				}

				$mutex = Wait-DeviceAssetIDMutex -API_Key $API_Key
				if (-not $mutex.CurrentlyAccessed) {
					$mutex.currentlyaccessed = $true
					$mutex.setby = $UID

					Set-DeviceAssetIDMutex -API_Key $API_Key -mutex $mutex | Write-Verbose

					$setby = (Get-DeviceAssetIDMutex -API_Key $API_Key).setby
					if ($setby -eq $UID -or $setby -eq $resetValue) {
						return $mutex
					} else {
						Start-Sleep -Seconds 1
						return Protect-DeviceAssetIDMutex -API_Key $API_Key -recursionCounter ($recursionCounter + 1)
					}
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