function Initialize-DeviceWindowsUpdate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]
		$packageProviderName = $DeviceDeploymentDefaultConfig.WindowsUpdate.packageProviderName,

		[Parameter()]
		[int]
		$packageProviderMinVersion = $DeviceDeploymentDefaultConfig.WindowsUpdate.packageProviderMinVersion,

		[Parameter()]
		[string]
		$packageName = $DeviceDeploymentDefaultConfig.WindowsUpdate.packageName,

		[Parameter()]
		[int]
		$packageMinVersion = $DeviceDeploymentDefaultConfig.WindowsUpdate.packageMinVersion

	)

	begin {
		$errorList = @()
	}
	process {
		try {
			try {
				if ([int]"$((Get-PackageProvider | Where-Object {$_.Name -eq $packageProviderName}).Version)".split(".")[0] -lt $packageProviderMinVersion) { #Extract the major version number and compare
					Write-Error -ErrorAction Stop -Message "$packageProviderName version $packageProviderMinVersion.xxx not Installed"
				}
			} catch {
				Write-Verbose "Installing $packageProviderName"
				Install-PackageProvider -Name $packageProviderName -Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -ErrorAction:$ErrorActionPreference
			}

			try {
				if ([int]"$((Get-Package | Where-Object {$_.Name -eq $packageName}).Version)".split(".")[0] -lt $packageMinVersion) { #Extract the major version number and compare
					Write-Error -ErrorAction Stop -Message "$packageName version $packageMinVersion.xxx not Installed"
				}
			} catch {
				Install-Package -Name $packageName -Force -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
			}

			Import-Module -Name $packageName -Force -Verbose:$VerbosePreference
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