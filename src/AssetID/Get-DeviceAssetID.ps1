function Get-DeviceAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$serialNumber,

		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter()]
		[string]$FreshAssetIDAttr = $DeviceDeploymentDefaultConfig.AssetID.freshAssetIDAttr


	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($serialNumber)) {
			try {
				$freshAsset = $null	
				try {
					#see if the serial number has freshAsset
					$freshAsset = Get-FreshAsset -API_Key $API_Key -serialNum $serialNumber -ErrorAction Stop
					$AssetID = $freshAsset.$FreshAssetIDAttr
					
					if (-not (Test-AssetID -AssetID $AssetID)) {
						Write-Verbose "Asset id in fresh ($AssetID), is invalid, generating a new one"
						throw
					}

				} catch {
					$AssetID = Get-NextAssetID -API_Key $API_Key -ErrorAction SilentlyContinue -whatif:$WhatIfPreference
					
				}
				
				return [PSCustomObject]@{
					AssetID = $AssetID
					freshAsset = $freshAsset
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