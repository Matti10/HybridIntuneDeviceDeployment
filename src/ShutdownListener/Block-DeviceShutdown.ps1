
# Documentation
<#

.SYNOPSIS
The Block-DeviceShutdown function is used to block and cancel pending shutdowns on a device.

.DESCRIPTION
The function creates and starts a PowerShell job that runs a continuous loop, checking for pending shutdowns in an interval specified by the $waitSeconds parameter. If a shutdown is detected, the function attempts to cancel it.

.PARAMETER jobName
An optional parameter that specifies the name of the background job. If not provided, the job name is fetched from the $DeviceDeploymentDefaultConfig predefined configuration variable.

.PARAMETER waitSeconds
An optional parameter that specifies the number of seconds the function waits before checking for shutdowns again. If not provided, the waiting time is fetched from the $DeviceDeploymentDefaultConfig predefined configuration variable.

.EXAMPLE
Block-DeviceShutdown -jobName "BlockShutdownJob" -waitSeconds 10
This example starts a job named 'BlockShutdownJob' that checks and cancels any pending shutdown every 10 seconds.

.INPUTS
None. You cannot pipe inputs to this function.

.OUTPUTS
The function returns the job that it starts on successful execution. In case of failure, it writes errors to the Error pipeline.

.LINK
Start-Job

.NOTES
This function requires administrative privileges to successfully abort shutdowns.

#>

function Block-DeviceShutdown {
    [CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Job name for Start-Job cmdlet.
		[Parameter()]
		[string]$jobName = $DeviceDeploymentDefaultConfig.shutdownListener.jobName,

		# The interval between each shutdown check (in seconds).
		[Parameter()]
		[int]$waitSeconds = $DeviceDeploymentDefaultConfig.shutdownListener.waitSeconds
	)

	begin {
		# Initializing the array to hold error messages.
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			# Start a job to constantly check and abort any upcoming shutdown.
			return Start-Job -Name $jobName -ScriptBlock {
				Start-Transcript -Path "C:\Intune_Setup\Logs\$fileName-$timestamp-$jobName.txt"
				while ($true)
				{
					try {
						# Try to abort any upcomping shutdown.
						shutdown -a
					}
					catch {
						# Catch any error occurred during the shutdown abort.
						$_
					}
					# Wait for the specified number of seconds before next shutdown check.
					Start-Sleep -Seconds $waitSeconds
				}    
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			# Catch all the errors occurred during the execution and stop the execution.
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}