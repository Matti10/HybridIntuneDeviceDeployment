
<#


.Synopsis
This function is responsible for repairing a device Asset ID Mutex, used to ensure safe access to data across threads.
The function uses the mutually exclusive set access to ensure protection against concurrent access issue.

.Description

The function Repair-DeviceAssetIDMutex utilizes a mutex to allow multiple threads a safe, singular access to a shared resource. The function is explicitly used to sleep, reset, and repair a DeviceAssetIDMutex.

When initiated, the process begins with a brief sleep to allow other resources to cease access. After this sleep, the mutex resets with default values dictated by configuration settings.

The function is uttered with `SupportsShouldProcess` cmdlet for declaration, which offers built-in -WhatIf and -Confirm parameters behaviour.

The function also includes error handling, stewing all errors to an `$errorList` array for later review.



.Parameter notAccessedValue
(optional): If provided, this value represents a not accessed value for the asset ID. Default value is retrieved from `$DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue`.

.Parameter resetValue
(optional): This parameter represents a reset value for the Asset ID. Default configuration setting is retrieved from `$DeviceDeploymentDefaultConfig.AssetID.resetValue`.

.Outputs

The final output is derived from `Set-DeviceAssetIDMutex` operation with passed mutex object. In case of a failure during the operation, the error message is appended to an `$errorList` and displayed at the end of the process.

.Example

To utilize the **Repair-DeviceAssetIDMutex** function in your script, call the function with the desired parameters:


Repair-DeviceAssetIDMutex -notAccessedValue "New_NotAccessedValue" -resetValue "New_ResetValue"

.Notes
The function begins by initializing an array to track errors over time. In the `process` block, the function tests if the mutex should perform a process using `ShouldProcess`. In the `end` block, if any errors are detected they are displayed.

Any exceptions encountered during this process will be caught, appended to an error list and written out in the error output. 

Lastly, throughout the function you'll notice calls to the `Write-Error` cmdlet. This cmdlet sends a terminating error to the error pipeline, stopping execution and indicating the failure point.
#>
function Repair-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (


		[Parameter()]
		[string]$notAccessedValue = $DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue,

		[Parameter()]
		$resetValue = $DeviceDeploymentDefaultConfig.AssetID.resetValue
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("The Device Asset Mutex")) {
			try {
				
				Start-Sleep -Seconds 10 # sleep to allow other resources to stop accessing

				$mutex = [PSCustomObject]@{
					currentlyaccessed = $false
					setby = $resetValue
				}

				return Set-DeviceAssetIDMutex -mutex $mutex

				Write-Error "Mutex value was outside of expected range, it has been reset to '$mutex'"

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