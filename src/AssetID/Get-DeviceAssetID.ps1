
# Documentation
<#
.SYNOPSIS
A function to retrieve asset ID for a device using its serial number.

.DESCRIPTION
The function gets the asset ID of a device by either fetching it from the "freshAsset" using the serial number or generating a new one if the asset ID is invalid. In case of any errors during the process, it adds them all in a list and throws them at the end of the function.

If the Asset ID could be retrieved or generated successfully, it can show a user message if the $disaplyUserOutput switch is provided.

.PARAMETER serialNumber
Mandatory parameter. Specifies the serial number of the device to get the asset ID for.

.PARAMETER FreshAssetIDAttr
Optionally specify the attribute name to get the asset ID from "fresh assets". By default, it uses the value from the default configuration of device deployment.

.PARAMETER disaplyUserOutput
A switch parameter. If present, shows a user message displaying the asset ID using the attribute from $messageTemplates.

.PARAMETER messageTemplates
Optionally specify the template to format the error messages. By default, it uses the templates from the default configuration of device deployment.

.EXAMPLE
PS> Get-DeviceAssetID -serialNumber "12345678" -displayUserOutput

.Retrieves the asset ID from the asset having serial number "12345678", and shows a user message presenting the retrieved asset ID.

.OUTPUTS
PSCustomObject. A custom object representing the AssetID of the device and the "freshAsset". 

.NOTES
If errors are encountered while performing actions, they are collected in an error list and thrown at the end.
#>

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
			New-BuildProcessError -errorObj $_ -message "Getting Device AssetID has failed. Check fresh assets for anything suspcious" -functionName "Get-DeviceAssetID" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
			throw "##TODO"
		}
	}	
}