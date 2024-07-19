function Set-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (


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
					return Repair-DeviceAssetIDMutex
				}

				return (Set-FreshCustomObject -objectID $objectID -recordID $recordID -record $mutex).custom_object.data
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