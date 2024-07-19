function Get-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (


		[Parameter()]
		[string]$objectID = $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectID,

		[Parameter()]
		[string]$recordID = $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectRecordID,

		[Parameter()]
		[string]$accessedValue = $DeviceDeploymentDefaultConfig.AssetID.AccessedValue,

		[Parameter()]
		[string]$notAccessedValue = $DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($recordID)) {
			try {
				$value = (Get-FreshCustomObject -objectID $objectID) | Where-Object {$_.bo_display_id -eq $recordID} #there is only one record, get position one just to be sure

				if ($value.CurrentlyAccessed -eq $notAccessedValue) {
					$currentlyAccessed = $false
				} elseif ($value.CurrentlyAccessed -eq $accessedValue) {
					$currentlyAccessed = $true
				} else {
					return Repair-DeviceAssetIDMutex
				}

				return [PSCustomObject]@{
					currentlyaccessed = $CurrentlyAccessed
					setby = $value.SetBy
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}