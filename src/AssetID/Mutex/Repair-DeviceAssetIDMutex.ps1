function Repair-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter()]
		[string]$notAccessedValue = $DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue,

		[Parameter()]
		$resetValue = $DeviceDeploymentDefaultConfig.AssetID.resetValue
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("The Device Asset Mutex")) {
			try {
				
				Start-Sleep -Seconds 10 # sleep to allow other resources to stop accessing

				$mutex = [PSCustomObject]@{
					currentlyaccessed = $false
					setby = $resetValue
				}

				return Set-DeviceAssetIDMutex -API_Key $API_Key -mutex $mutex

				Write-Error "Mutex value was outside of expected range, it has been reset to '$mutex'"

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