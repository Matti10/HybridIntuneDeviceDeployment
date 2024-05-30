function Register-DeviceWithFresh {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter()]
		$localDeviceInfo = (Get-DeviceLocalData -API_Key $API_Key)
	)
	
	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("The current device")) {
				
				#Use mutex to protect names from concurrent access 
				$mutex = Protect-DeviceAssetIDMutex -API_key $API_Key -Verbose:$VerbosePreference
				
				$AssetIDInfo = (Get-DeviceAssetID -API_Key $API_Key -serialNumber $localDeviceInfo.serialNumber)
				
				$freshAsset = $AssetIDInfo.freshAsset
				$AssetID = $AssetIDInfo.AssetID

				#test if fresh asset exists
				if ($null -ne $freshAsset) {
					#test if fresh assets name is correct 
					if ($freshAsset.Name -ne $AssetID) {
						Set-FreshAssetName -FreshAsset $freshAsset -API_Key $API_Key -name $AssetID
					}
				} else {
					New-FreshAsset -API_Key $API_Key -name $AssetID -type $localDeviceInfo.type -model $localDeviceInfo.model -serial $localDeviceInfo.serialNumber

					Start-Sleep -Milliseconds 500 #sleep breifley to allow asset to be created before checking it exists and returning
				}

				$mutex = Unprotect-DeviceAssetIDMutex -API_key $API_Key -mutex $mutex  -Verbose:$VerbosePreference

				return Get-FreshAsset -API_Key $API_Key -name $AssetID -ErrorAction Stop
		}
		}
		catch {
			Unprotect-DeviceAssetIDMutex -API_key $API_Key -mutex $mutex

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