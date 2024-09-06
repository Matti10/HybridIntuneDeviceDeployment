
<# Documentation
.SYNOPSIS
This PowerShell function Invoke-DeviceDeploymentCleanupCommands is utilized for the cleanup after a deployment to a device. This involves unblocking the device shutdown, removing temporary data from the deployment and checking a mutex to ensure it is not stuck. It will also disconnect from the Azure account that was used in deployment.

.INPUTS
None. You cannot pipe objects to Invoke-DeviceDeploymentCleanupCommands.

.OUTPUTS
This function does not return any output. 

.EXAMPLE
Invoke-DeviceDeploymentCleanupCommands

Running this command will perform a series of cleanup commands after a device deployment. 

.NOTES
This function uses error handling to catch any exceptions that occur in the process block. If an error occurs, it is captured in a list of errors. At the end of the function, if any errors were recorded, they are written into a single concatenated error message and thrown as a terminating error.
#>
function Invoke-DeviceDeploymentCleanupCommands {
	# Binds the cmdlet to accept -Verbose, -Debug, -WhatIf and -Confirm parameters. 
	[CmdletBinding(SupportsShouldProcess = $true)]
	param ()

	begin {
		# Instantiating an array to catch errors.
		$errorList = @()
	}
	process {
		try {
			# Unblock the device shutdown command
			Unblock-DeviceShutdown
			# Remove the temporary data created during the device deployment
			Remove-DeviceDeploymentTempData
			# A "TODO" message for the users/developers to make sure the mutex is not stuck. To be implemented.
			THROW "##TODO check mutex is not stuck"
			# Disconnect the Azure account used for the deployment
			Disconnect-AzAccount
		}
		catch {
			# Add the error to the error list and write the error to the terminal
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		# If any errors occurred during command execution, write them all into a single error message and throw it
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}