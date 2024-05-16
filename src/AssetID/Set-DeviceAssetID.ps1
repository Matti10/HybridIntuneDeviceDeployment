function Set-DeviceAssetID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[Object]$buildInfo,

		[Parameter(Mandatory)]
		[string]$API_Key

	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($serialNumber)) {
			try {
				Protect-DeviceAssetIDMutex -API_Key $API_Key

				$AssetID = Get-DeviceAssetID

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