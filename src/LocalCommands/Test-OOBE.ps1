
# Documentation
<#
.SYNOPSIS
Tests if the device is in Out of Box Experience (OOBE) state.

.DESCRIPTION
The Test-OOBE function checks if the device is in an OOBE state by checking if there is any user with the name "defaultUser" in the process user list. It uses built-in power shell cmdlet "Get-Process" to fetch user name of processes.

.PARAMETER None
This function does not take any parameters.

.EXAMPLE
Test-OOBE

Returns $true if the machine is in OOBE state, otherwise $false.

.INPUTS
None

.OUTPUTS
Boolean. The cmdlet returns $true if the machine is in OOBE state, $false otherwise.


.NOTES
Caller of this cmdlet should have necessary permissions to execute Get-Process cmdlet.
Author: Your Name
Date Created: Date
#>



function Test-OOBE {
	
	# Support for -WhatIf, -Confirm flags
	[CmdletBinding(SupportsShouldProcess = $true)]
	param ()

	begin {
		# Initialize error list
		$errorList = @()
	}

	process {
		# Checks to confirm the execution
		if ($PSCmdlet.ShouldProcess((hostname))) {
			try {
				# the current state of the machine, false by default
				$oobe = $false
				# Get the user names who are currently running a process on the machine
				$procUsers = (Get-Process -IncludeUserName -Verbose).UserName
				
				# Check each user 
				foreach ($user in $procUsers) {
					# If a user by the name 'defaultUser' exists, then the machine is in OOBE state
					if ($user -like "*defaultUser*") {
						$oobe = $true
						break
					}
				}
				# Return the state
				return $oobe
			}
			catch {
				# If there is an exception add it to the errorList and write the error to error stream
				$errorList += $_
				Write-Error $_

				return $false
			}
		}
		else {
			return $true
		}
	}
	end {
		# If there are any exceptions/errors occured during the execution of cmdlet, write them to the error stream and stop the execution.
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}