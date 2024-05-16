function Set-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter(Mandatory)]
		[Object]$mutex,

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
				if ($mutex.CurrentlyAccessed -eq $true) {
					$mutex.CurrentlyAccessed = $accessedValue
				} elseif ($mutex.CurrentlyAccessed -eq $false) {
					$mutex.CurrentlyAccessed = $notAccessedValue
				} else {
					return Repair-DeviceAssetIDMutex -API_Key $API_Key
				}

				return (Set-FreshCustomObject -API_Key $API_Key -objectID $objectID -recordID $recordID -record $mutex).custom_object.data
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