function Test-AssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$AssetID,

		[Parameter()]
		[string]$AssetIDPrefix = $DeviceDeploymentDefaultConfig.AssetID.AssetIDPrefix,

		[Parameter()]
		[int]$AssetIDLength = $DeviceDeploymentDefaultConfig.AssetID.AssetIDLength
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("Testing Asset ID $AssetID")) {
				if ($AssetID.Length -ne $AssetIDLength) {
					return $false
				}

				if ($AssetID -notlike "$AssetIDPrefix*") {
					return $false
				}

				return $true
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