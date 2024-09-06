
# Documentation
<#
.SYNOPSIS
This function is designed to generate the next appropriate AssetID based on various parameters.

.DESCRIPTION
The function 'Get-NextAssetID' fetches fresh asset IDs, checks the IDs starting with the provided prefix, and identifies the largest ID. It then generates a new AssetID that's one increment larger, while maintaining a consistent length for all AssetIDs.

.PARAMETER FreshAssetIDAttr
The attribute of a fresh Asset ID in the deployment configuration.

.PARAMETER adAssetIDAttr
The attribute of the Asset ID in the deployment configuration associated with Active Directory.

.PARAMETER DeviceADScope
The location in Active Directory where the devices are stored.

.PARAMETER AssetIDPrefix
The prefix that all Asset IDs must start with.

.PARAMETER AssetIDLength
The determined length of the Asset ID.

.EXAMPLE
Get-NextAssetID -FreshAssetIDAttr 'asset001' -adAssetIDAttr 'asset001' -DeviceADScope 'OU=Workstations,DC=mydomain,DC=com' -AssetIDPrefix 'asset' -AssetIDLength 6

This would output a new AssetID with the prefix 'asset' that's one increment larger than the largest AssetID found, maintaining a length of 6 characters.
#>

function Get-NextAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (


		[Parameter()]
		[string]$FreshAssetIDAttr = $DeviceDeploymentDefaultConfig.AssetID.freshAssetIDAttr,

		[Parameter()]
		[string]$adAssetIDAttr = $DeviceDeploymentDefaultConfig.AssetID.adAssetIDAttr,

		[Parameter()]
		[string]$DeviceADScope = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope,

		[Parameter()]
		[string]$AssetIDPrefix = $DeviceDeploymentDefaultConfig.AssetID.AssetIDPrefix,

		[Parameter()]
		[string]$AssetIDLength = $DeviceDeploymentDefaultConfig.AssetID.AssetIDLength
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("Getting Next Asset ID")) {
				
				# Get All Asset IDs
				$All = (Get-FreshAsset -all -pageLimit 3).$FreshAssetIDAttr #page limit of 3 so only 90 most recently updated devices are returned (its way quicker)
				# $All += (Get-ADComputer -SearchBase $DeviceADScope -Filter *).$adAssetIDAttr
				# Currently not being used as it requires RSAT installed on Build device. Techincally, all AD comps should be in fresh anyways, so shouldnt be nessecary....
				
				$max = 0
	
				#find the largest AssetID
				$All | Where-Object {$_ -like "$AssetIDPrefix*"} | ForEach-Object {
					try {
						$current = [int](($_ -split $AssetIDPrefix)[1])
					} catch {
						Write-Error $_
					}
					if ($current -gt $max) {
						$max = $current
					}
				}

				do {
					#update max
					$max = $max +1
					#Add prefix
					$nextAssetID = "$AssetIDPrefix$($max)"
		
					# pad asset ID with '0' until correct length reached
					while ($nextAssetID.Length -lt $AssetIDLength) {
						$AssetIDPrefix = $AssetIDPrefix + "0"
		
						$nextAssetID = "$AssetIDPrefix$($max + 1)"
					}
				} while ($null -ne (Get-FreshAsset -name $nextAssetID -ErrorAction SilentlyContinue))

				return $nextAssetID
	
			}
		}
		catch {
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