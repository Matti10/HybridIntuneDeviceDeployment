function Get-DeviceAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$serialNumber,

		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter()]
		[string]$FreshAssetIDAttr = $DeviceDeploymentDefaultConfig.Generic.freshAssetIDAttr
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($serialNumber)) {
			try {
				try {
					$AssetID = (Get-FreshAsset -API_Key $API_Key -serialNum $serialNumber -ErrorAction Stop).$FreshAssetIDAttr
				} catch {
					$AssetID = Get-NextAssetID -API_Key $API_Key -ErrorAction SilentlyContinue
				}
				
				return $AssetID
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