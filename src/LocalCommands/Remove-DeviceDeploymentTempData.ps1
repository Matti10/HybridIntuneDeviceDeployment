
<#
.SYNOPSIS   
This function is used to clean up the temporary data of device deployment.

.DESCRIPTION  
Remove-DeviceDeploymentTempData removes any downloaded tricare and external modules in the specified root directory except for items residing in log directory. Any errors received during the process are captured and dumped to the console.

.PARAMETER rootDirectory   
The root directory to check for downloaded modules. By default, it gets the root directory path from a configuration file.

.PARAMETER logDirectory
The directory that contains log files which should not be removed. By default, it gets the log directory path from a configuration file.

.EXAMPLE   
Remove-DeviceDeploymentTempData -RootDirectory "C:\Temp" -LogDirectory "C:\Logs"

This will remove all the downloaded modules from the directory "C:\Temp" and its subdirectories, excluding the directory "C:\Logs".
#>
function Remove-DeviceDeploymentTempData {
	# Binds the needed arguments for the Cmdlet to be usable from the command line.
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Allows input of the root directory path. Defaults to value in config file.
		[Parameter()]
		[string]$rootDirectory = $DeviceDeploymentDefaultConfig.Generic.buildPCRootPath,

		# Allows input of the log directory path. Defaults to value in config file.
		[Parameter()]
		[string]$logDirectory = $DeviceDeploymentDefaultConfig.Logging.buildPCLogPath
	)

	begin {
		# Initializes an error list array.
		$errorList = @()
	}
	process {
		try {
			# Queries the root directory and its subdirectories for tricare modules and removes them.
			Get-ChildItem -Path $rootDirectory -Recurse -Depth 100 | Where-Object {$_.FullName -notLike "*$($logDirectory)*"} | Remove-Item -Force -Recurse -Confirm:$false -WhatIf:$WhatIfPreference

			# Removes all the currently installed PowerShell modules.
			Get-InstalledModule | Uninstall-Module
		}
		catch {
			# If an error occurs, add it to the error list and output it.
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		# If there were any errors, output all of them.
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}