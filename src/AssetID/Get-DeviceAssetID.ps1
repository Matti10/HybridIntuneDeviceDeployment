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
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			throw "##TODO"
			New-BuildProcessError -errorObj $_ -message "Getting Device AssetID has failed. Check fresh assets for anything suspcious" -functionName "Remove-DeviceADDuplicate" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
		}
	}	
}