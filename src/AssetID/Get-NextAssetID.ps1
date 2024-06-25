function Get-NextAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

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
				$All = (Get-FreshAsset -API_Key $API_Key -all -pageLimit 3).$FreshAssetIDAttr #page limit of 3 so only 90 most recently updated devices are returned (its way quicker)
				$All += (Get-ADComputer -SearchBase $DeviceADScope -Filter *).$adAssetIDAttr
	
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
				} while ($null -ne (Get-FreshAsset -API_Key $API_Key -name $nextAssetID -ErrorAction SilentlyContinue))
	
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}
}