function Remove-DeviceDeploymentTempData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]$rootDirectory = $DeviceDeploymentDefaultConfig.Generic.buildPCRootPath,

		[Parameter()]
		[string]$logDirectory = $DeviceDeploymentDefaultConfig.Logging.buildPCLogPath
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			#remove downloaded tricare modules
			Get-ChildItem -Path $rootDirectory -Recurse -Depth 100 | Where-Object {$_.FullName -notLike "*$($logDirectory)*"} | Remove-Item -Force -Recurse -Confirm:$false -WhatIf:$WhatIfPreference

			#remove downloaded external modules
			Get-InstalledModule | Uninstall-Module
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