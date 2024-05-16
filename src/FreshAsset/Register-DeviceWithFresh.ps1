function Register-DeviceWithFresh {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$deviceInfo = Get-DeviceLocalData -API_Key $API_Key
			$AssetIDInfo = Get-DeviceAssetID -API_Key $API_Key -serialNumber $deviceInfo.serialNumber

			$freshAsset = $AssetIDInfo.freshAsset
			$AssetID = $AssetIDInfo.AssetID

			#Use mutex to protect names from concurrent access 
			$mutex = Protect-DeviceAssetIDMutex -API_key $API_Key
			#test if fresh asset exists
			if ($null -ne $freshAsset) {
				#test if fresh assets name is correct 
				if ($freshAsset.Name -ne $AssetID) {
					Set-FreshAssetName -FreshAsset $freshAsset -API_Key $API_Key -name $AssetID
				}
			} else {
				New-FreshAsset -API_Key $API_Key -name $AssetID -type $deviceInfo.type -model $deviceInfo.model -serial $deviceInfo.serialNumber
			}

			Unprotect-DeviceAssetIDMutex -API_key $API_Key -mutex $mutex

			return Get-FreshAsset -API_Key $API_Key -name $AssetID -ErrorAction Stop
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}