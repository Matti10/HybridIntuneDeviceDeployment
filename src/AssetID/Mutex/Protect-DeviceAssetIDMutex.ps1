function Protect-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (


		[Parameter()]
		$recursionCounter = 0,

		[Parameter()]
		$timeoutValue = $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds,

		[Parameter()]
		$UID = "$(hostname)-$((Get-Date -format "yyyy-MM-dd-hh-ss-fffffff"))",

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

				$mutex = Wait-DeviceAssetIDMutex -Verbose:$VerbosePreference
				if (-not $mutex.CurrentlyAccessed) {
					$mutex.currentlyaccessed = $true
					$mutex.setby = $UID

					Set-DeviceAssetIDMutex -mutex $mutex | Write-Verbose

					$setby = (Get-DeviceAssetIDMutex).setby
					if ($setby -eq $UID -or $setby -eq $resetValue) {
						return $mutex
					} else {
						Start-Sleep -Seconds 1
						return Protect-DeviceAssetIDMutex -recursionCounter ($recursionCounter + 1)  -Verbose:$VerbosePreference
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