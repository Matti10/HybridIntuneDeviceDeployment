
<#
.SYNOPSIS
This function is designed to wait for a Device Asset ID Mutex.

.DESCRIPTION
The Wait-DeviceAssetIDMutex function waits for the availability of the Device Asset ID Mutex. 
It continuously checks for the mutex and only proceeds onwards when it becomes available. 
If the mutex does not become available within a specified timeout duration, an error is thrown.

.PARAMETER timeoutValue
The duration for which the function should wait for the Device Asset ID Mutex to be available before timing out. 
The default value is derived from the $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds variable.

.EXAMPLE
Wait-DeviceAssetIDMutex
This command will attempt to wait for the Device Asset ID Mutex to be available, 
using the default timeout value stored in the $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds variable.

.EXAMPLE
Wait-DeviceAssetIDMutex -timeoutValue 120
This command will attempt to wait for the device asset ID mutex to be available for up to 120 seconds.

.NOTES
In case of any error during the process, it will stop the script and display the error message. 
The error messages are stored in an array $errorList for tracking purposes.
#>

function Wait-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Timeout duration for waiting the mutex. The default value is derived from a system variable.
		[Parameter()]
		$timeoutValue = $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds
	)

	begin {
		# Initialize an array to store any errors that occur during the process.
		$errorList = @()
	}
	process {
		# This block starts the process of waiting for the AssetID Mutex.
		if ($PSCmdlet.ShouldProcess("AssetID Mutex")) {
			try {
				$count = 0
				# This loop will continuously check if the mutex is available until the defined timeout value.
				while ((Test-DeviceAssetIDMutex)) {
					# If the count of check times is greater than timeout value, then it stops the process and returns an error.
					if ($count -gt $timeoutValue) {
						Write-Error -Message "Testing Mutex has timed out `n" -ErrorAction Stop
					}

					Write-Verbose "Waiting on Mutex"
					# Pause the script to sleep for 1 second.
					Start-Sleep -Seconds 1
					# Increase the count value.
					$count += 1
				} 

				return Get-DeviceAssetIDMutex
			}
			catch {
				# Add the error message into the error array and display the error.
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		# If the error array has one or more errors, then returns the errors and stops the script.
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}