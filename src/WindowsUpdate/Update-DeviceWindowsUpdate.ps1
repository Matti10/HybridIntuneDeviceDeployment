
# Documentation
<#
.SYNOPSIS
This PowerShell function Update-DeviceWindowsUpdate updates Windows on the calling device.

.DESCRIPTION
Update-DeviceWindowsUpdate is a function that uses a cmdlet Install-WindowsUpdate to handle all updates on the local machine. The function is divided into three stages: Begin, Process, and End. 
- The Begin stage initializes an empty error list array.
- The Process stage then attempts to install Windows updates, where it ignores any prompts for rebooting and accepts all updates, with verbose output that is based on the $VerbosePreference setting.
- If any error occurs during the installation, it catches and writes the error to the $errorList array.
- The End stage then checks if there are any entries in the $errorList. If there are, it stops the script and writes all errors to the console with a detailed call stack trace for troubleshooting.

.PARAMETER 
There are no parameters for this cmdlet.

.EXAMPLE
Update-DeviceWindowsUpdate

This will begin the Update-DeviceWindowsUpdate process on the local machine, and will start installing any available Windows updates. If an error occurs, it will also stop the script and return an exception.

.INPUTS
None. You cannot pipe inputs to Update-DeviceWindowsUpdate.

.OUTPUTS
If there are no errors during the update process, there will be no output. However, if an error occurs, it logs the error and outputs a detailed error message.

.NOTES
More information about the Install-WindowsUpdate cmdlet that has been used in this function can be found at URL: https://www.powershellgallery.com/packages/PSWindowsUpdate/2.1.1.2/Content/Install-WindowsUpdate.ps1 

#>
function Update-DeviceWindowsUpdate {
	# Support should process parameter (simulate, confirm)
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	# No parameters for this function.
	)

	begin {
		# Initialize an array for collected errors
		$errorList = @()
	}
	process {
		# Check if the function should process using hostname
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			# Try the installation; protected by a try-catch block to manage exceptions
			try {
				# Install Windows updates, ignore reboots, accept all defaults, allow 2 recurse cycles, and print verbose output
				Install-WindowsUpdate -Install -IgnoreReboot -AcceptAll -recurseCycle 2 -verbose:$VerbosePreference
			}
			catch {
				# If an error occurs, append the error information to the error list and write the error message
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		# If any errors occurred during process block, write them and stop execution
		if ($errorList.count -ne 0) {
			# Write a custom error message with all collected errors and the call stack
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}