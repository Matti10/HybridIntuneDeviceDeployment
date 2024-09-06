
<#
.SYNOPSIS
A PowerShell function that protects the Mutex of a device asset ID.

.DESCRIPTION
The Protect-DeviceAssetIDMutex function tries to acquire a Mutex for a given device asset ID. 
If the Mutex is not currently accessed by any process, it sets the Mutex as accessed and sets the access UID to the provided or default UID.
If the Mutex is already accessed, it will recursively call itself until acquiring the Mutex or exceeding the timeout limit.

.PARAMETER recursionCounter
Number of times the function has already recursively called itself to try and acquire the Mutex. 
If this value reaches 1/4 of the timeoutValue, the function will time out and return an error.
It defaults to 0.

.PARAMETER timeoutValue
The amount of time, in seconds, after which the function should time out and return an error.
Fetches the value from $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds by default.

.PARAMETER UID
Unique identifier of the device asset ID that is trying to acquire the Mutex. 
Defaults to the combination of the hostname and the current date-time down to fractions of a second.

.PARAMETER resetValue
Reset value of the device asset ID that is used when releasing the Mutex. 
Fetches the value from $DeviceDeploymentDefaultConfig.AssetID.resetValue by default.

.EXAMPLE
Protect-DeviceAssetIDMutex

.NOTES
In addition to the explained detailed inline comments in the code, it is important to note that the usage of recursion and iteration here is meant to handle scenarios where contention for the Mutex can lead to multiple processes or threads intensively using the CPU waiting to acquire the Mutex. 'Wait-DeviceAssetIDMutex', 'Set-DeviceAssetIDMutex' and 'Get-DeviceAssetIDMutex' are assumed to be pre-defined functions that handle the mutex operations with their corresponding functionalities.

The function only performs its actions when run with the 'ShouldProcess' advanced function switch.
It gathers all the errors occurred during the process execution in a list and writes them to an error stream at the end of the execution.
#>

function Protect-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		$recursionCounter = 0, # Initialize the recursion counter

		[Parameter()]
		$timeoutValue = $DeviceDeploymentDefaultConfig.AssetID.MutexTimeoutSeconds, # Set the timeout value

		[Parameter()]
		$UID = "$(hostname)-$((Get-Date -format "yyyy-MM-dd-hh-ss-fffffff"))", # Generate a unique UID

		[Parameter()]
		$resetValue = $DeviceDeploymentDefaultConfig.AssetID.resetValue # Set the reset value
	)

	begin {
		$errorList = @() # Initialize errors list
	}
	process {
		if ($PSCmdlet.ShouldProcess($UID)) { # Check if it should process the cmdlet
			try {
                # Check if it timeout or not
				if ($recursionCounter -gt ($timeoutValue/4)){
					Write-Error "Protecting Mutex has timed out.`n$mutex" -ErrorAction Stop
				}

				$mutex = Wait-DeviceAssetIDMutex -Verbose:$VerbosePreference # Acquire Mutex
                # If Mutex is not accessed, acquire it
				if (-not $mutex.CurrentlyAccessed) {
					$mutex.currentlyaccessed = $true
					$mutex.setby = $UID

					Set-DeviceAssetIDMutex -mutex $mutex | Write-Verbose

					$setby = (Get-DeviceAssetIDMutex).setby
                    # If Mutex is acquired successfully, return it
					if ($setby -eq $UID -or $setby -eq $resetValue) {
						return $mutex
					} else {
                        # If Mutex is not acquired, try again
						Start-Sleep -Seconds 1
						return Protect-DeviceAssetIDMutex -recursionCounter ($recursionCounter + 1)  -Verbose:$VerbosePreference
					}
				}
			}
			catch {
				$errorList += $_ # Catch and add error to error list
				Write-Error $_
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
            # If any errors occurred during execution, write them to error stream
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}