
<# Documentation
.SYNOPSIS
This PowerShell function, Initialize-DeviceWindowsUpdateEnviroment, is used to initialize a windows update environment on a device. The initialization includes the installation of required packages and modules.

.DESCRIPTION
The function checks for the minimum required versions of the package provider and the package. If the requirements are not met, the function will attempt to install the necessary versions. 

In case of any errors during this process, they will be captured in an error list and returned at the end of the function.



.PARAMETER packageProviderName
`[string]`This parameter takes the name of the package provider needed for the update. By default, it is set to the `packageProviderName` from `WindowsUpdate` configuration in the `DeviceDeploymentDefaultConfig` variable.

.PARAMETER packageProviderMinVersion
`[int]`This is the minimum version number of the package provider necessary for the update. It defaults to the `packageProviderMinVersion` from `WindowsUpdate` configuration in the `DeviceDeploymentDefaultConfig` variable.

.PARAMETER packageName
`[string]`This parameter represents the name of the package required for the update. By default, it is set to the `packageName` from `WindowsUpdate` configuration in the `DeviceDeploymentDefaultConfig` variable.

.PARAMETER packageMinVersion
`[int]`This is the minimum required version of the package for the update. It defaults to the `packageMinVersion` from `WindowsUpdate` configuration in the `DeviceDeploymentDefaultConfig` variable.

.EXAMPLE

Initialize-DeviceWindowsUpdateEnviroment -packageProviderName "NuGet" -packageProviderMinVersion 2 -packageName "PowerShellGet" -packageMinVersion 1

In this example, the function will initialize the windows update environment using the NuGet package provider with a minimum version of 2, and the package 'PowerShellGet' with a minimum version of 1. The function will also attempt to install these as necessary.

.NOTES
The function supports the `-WhatIf` switch by setting the `$WhatIfPreference` inside the function. If set to `$true`, the function will only simulate its actions. The `-Verbose` switch is also supported. If enabled, the function will output additional debugging details.

In the event of any failure by the function, it will output an error message containing specifics about where exactly the function failed.
#>
function Initialize-DeviceWindowsUpdateEnviroment {
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}