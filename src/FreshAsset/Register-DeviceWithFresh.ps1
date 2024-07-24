function Register-DeviceWithFresh {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		$localDeviceInfo = (Get-DeviceLocalData)
	)
	
	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("The current device")) {
				
				#Use mutex to protect names from concurrent access 
				$mutex = Protect-DeviceAssetIDMutex -Verbose:$VerbosePreference
				
				$AssetIDInfo = (Get-DeviceAssetID -serialNumber $localDeviceInfo.serialNumber -disaplyUserOutput)
				
				$freshAsset = $AssetIDInfo.freshAsset
				$AssetID = $AssetIDInfo.AssetID

				#test if fresh asset exists
				if ($null -ne $freshAsset) {
					#test if fresh assets name is correct 
					if ($freshAsset.Name -ne $AssetID) {
						Set-FreshAssetName -FreshAsset $freshAsset -name $AssetID
					}
				} else {
					New-FreshAsset -name $AssetID -type $localDeviceInfo.type -model $localDeviceInfo.model -serial $localDeviceInfo.serialNumber

					Start-Sleep -Milliseconds 500 #sleep breifley to allow asset to be created before checking it exists and returning
				}

				$mutex = Unprotect-DeviceAssetIDMutex -mutex $mutex  -Verbose:$VerbosePreference

				Start-Sleep -Seconds 10 # pause to give time for fresh server to create asset

				return Get-FreshAsset -name $AssetID -ErrorAction Stop
		}
		}
		catch {
			Unprotect-DeviceAssetIDMutex -mutex $mutex

			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}