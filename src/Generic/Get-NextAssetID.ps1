function Get-NextAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$API_Key,

		[Parameter()]
		[string]$FreshAssetIDAttr = $DeviceDeploymentDefaultConfig.Generic.freshAssetIDAttr,

		[Parameter()]
		[string]$adAssetIDAttr = $DeviceDeploymentDefaultConfig.Generic.adAssetIDAttr,

		[Parameter()]
		[string]$DeviceADScope = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope,

		[Parameter()]
		[string]$AssetIDPrefix = $DeviceDeploymentDefaultConfig.Generic.AssetIDPrefix,

		[Parameter()]
		[string]$AssetIDLength = $DeviceDeploymentDefaultConfig.Generic.AssetIDLength
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("Getting Next Asset ID")) {
				# Get All Asset IDs
				$All = (Get-FreshAsset -API_Key $API_Key -all).$FreshAssetIDAttr
				$All += (Get-ADComputer -SearchBase $DeviceADScope -Filter *).$adAssetIDAttr
	
				$max = 0
	
				#find the largest AssetID
				$All
				| Where-Object {$_ -like "$AssetIDPrefix*"}
				| ForEach-Object {
					try {
						$current = [int]($_.split($AssetIDPrefix)[1])
					} catch {
						Write-Error $_
					}
					if ($current -gt $max) {
						$max = $current
					}
				}
				#TODO THIS NEEDS SOME KINDA OF MUTEX
				#Add prefix
				$nextAssetID = "$AssetIDPrefix$($max + 1)"
	
				# pad asset ID with '0' until correct length reached
				while ($nextAssetID.Length -lt $AssetIDLength) {
					$AssetIDPrefix = $AssetIDPrefix + "0"
	
					$nextAssetID = "$AssetIDPrefix$($max + 1)"
				}
	
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