<#
.SYNOPSIS
Function to unprotect a Device Asset ID Mutex which checks whether the remote mutex is set by the same entity, if so it sets the `currentlyaccessed` variable to false. It then re-sets the mutex.

.DESCRIPTION
The Unprotect-DeviceAssetIDMutex is designed to unprotect a mutex. The function first retrieves the remote mutex using the Get-DeviceAssetIDMutex function. It then validates if the remote mutex is set by the same actor as the provided mutex, if so it sets the `currentlyaccessed` field of the provided mutex to false, meaning that it is not currently being accessed, then it sets the new status of the mutex using the Set-DeviceAssetIDMutex function. If it cannot carry out this process, it writes an error to PowerShell.

.PARAMETER mutex 
(Mandatory Parameter) The mutex which needs to be unprotected.

.EXAMPLE

EXAMPLE 1
Unprotect-DeviceAssetIDMutex -mutex $mutex

.INPUTS
$mutex: The provided mutex instance.

.OUTPUTS
Standard PowerShell Error or console messages.

.NOTES
Make sure the identifying details of the mutex(grid of the mutex) is correct.

#>

function Unprotect-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		$mutex
		)
		
		# Begin block. Initializes empty errorList
	begin {
		$errorList = @()
	}
	# Process block. If should process condition is met, get remote mutex, check if mutex is set 
	# by the same entity. If so, set currentlyaccessed to false and re-set the mutex.
	process {
		if ($PSCmdlet.ShouldProcess("Device Asset ID Mutex")) {
			try {
				$remoteMutex = Get-DeviceAssetIDMutex

				if ($remoteMutex.setBy -eq $mutex.setBy) {
					$mutex.currentlyaccessed = $false
					return Set-DeviceAssetIDMutex -mutex $mutex
				} 
				# Write error with code, if set by a different mutex.
				else {
					Write-Error "Unable to unprotect mutex as it was set by a different actor `n $mutex"
				}
			}
			catch {
				# Catch error and put into errorList
				$errorList += $_
				Write-Error $_
			}
		}
	}

	# End block. If there are errors in execution, output error list and stop action.
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}	
	}
}