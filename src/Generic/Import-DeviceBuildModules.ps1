function Import-DeviceBuildModules {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		$modules = $DeviceDeploymentDefaultConfig.Dependencies
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("Importing Modules")) {
			try {
				foreach ($module in $modules) {
					Write-Verbose "Importing $module"
					Import-Module $module
				}
			}
			catch {
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}