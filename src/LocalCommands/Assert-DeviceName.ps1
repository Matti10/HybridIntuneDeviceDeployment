function Assert-DeviceName {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	
		[Parameter(Mandatory)]
		[string]
		$AssetID,

		[Parameter()]
		[switch]
		$retry

	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ("$(hostname)" -ne $AssetID) {
				Write-Verbose "Computer Name change failed. Current name is $(hostname) asset id is $AssetID"

				if ($retry) {
					Set-DeviceName -AssetId $AssetID
				} else {
					Write-Error "Renaming Computer failed. Current name is $(hostname) asset id is $AssetID. Please rename manually" -ErrorAction Stop
				}
				
			} else {
				Write-Verbose "Computer Name change correct. Current name is $(hostname) asset id is $AssetID"
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