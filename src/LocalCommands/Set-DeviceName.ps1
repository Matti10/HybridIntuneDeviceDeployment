function Set-DeviceName {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	
		[Parameter(Mandatory)]
		[string]
		$AssetID
	
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($AssetID)) {
			try {
				Rename-Computer -NewName $AssetID -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Force
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