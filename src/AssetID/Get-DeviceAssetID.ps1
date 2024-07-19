function Get-DeviceAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$serialNumber,

		[Parameter()]
		[string]$FreshAssetIDAttr = $DeviceDeploymentDefaultConfig.AssetID.freshAssetIDAttr,

		[Parameter()]
		[switch]$disaplyUserOutput,

		[Parameter()]
		$messageTemplates = $DeviceDeploymentDefaultConfig.DeviceUserInteraction.messages

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
					$freshAsset = Get-FreshAsset -serialNum $serialNumber -ErrorAction Stop
					$AssetID = $freshAsset.$FreshAssetIDAttr
					
					if (-not (Test-AssetID -AssetID $AssetID)) {
						Write-Verbose "Asset id in fresh ($AssetID), is invalid, generating a new one"
						throw
					}

				} catch {
					$AssetID = Get-NextAssetID -ErrorAction SilentlyContinue -whatif:$WhatIfPreference
					
				}
				
				if ($disaplyUserOutput) {
					Show-DeviceUserMessage -message $messageTemplates.assetIdAssignment.message -title $messageTemplates.assetIdAssignment.title -messageBoxConfigCode $messageTemplates.assetIdAssignment.messageBoxConfiguration -placeholderValue $AssetID
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}