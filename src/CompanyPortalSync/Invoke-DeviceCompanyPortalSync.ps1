
# Documentation
<#
.SYNOPSIS
This function, Invoke-DeviceCompanyPortalSync, is used to force synchronization of the Company Portal applicstion on a device managed by Microsoft Intune.

.DESCRIPTION
The function uses two methods to synchronize applications on the Company Portal. The first attempt is by checking if there is a scheduled task to do this on the local device and if so, start that task.

If there is no scheduled task, it is assumed the Company Portal is not installed on the device. Despite this it will attempt to force a sync anyway via a direct command to the Intune Management Extension.

If any errors occur during the function execution, details of these are collected and displayed at the end.

.PARAMETER syncTaskName
This is the name of the Scheduled Task created for Company Portal Sync on the local device.

If not provided, the default task name from the $DeviceDeploymentDefaultConfig.CompanyPortalSync.syncTaskName will be used.

.EXAMPLE
Invoke-DeviceCompanyPortalSync

This command will attempt to perform a sync with the default scheduled task name.

.EXAMPLE
Invoke-DeviceCompanyPortalSync -syncTaskName "CompanyPortalSyncTask"

This command will attempt to perform a sync using the specified scheduled task name.

.INPUTS
String

.OUTPUTS 
Error information if any error occurs

.NOTES
Any errors that occur during the syncing process will be captured in the $errorList array and displayed at the end of the function.

#>
function Invoke-DeviceCompanyPortalSync {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $syncTaskName = $DeviceDeploymentDefaultConfig.CompanyPortalSync.syncTaskName
    )

    # Start by initializing an empty array for any errors that may happen during the script
    begin {
        $errorList = @()
    }
    process {
		try {
            # First try finding a scheduled task that should be syncing the company portal
			$syncTask = Get-ScheduledTask | Where-Object {$_.TaskName -eq $syncTaskName} 
            
            # If there is no such task, write out a message indicating the company portal may not be installed (as we assume it manages the task)
			if ($null -eq $syncTask) {
				Write-Verbose "The Intune sync scheduled task doesn't exist, possibly due to company portal not being installed"
			} else {
                # If the task exists, start it and write out any verbose output
				$syncTask | Start-ScheduledTask -Verbose:$VerbosePreference
			}

            # Regardless of whether we found the task above, try syncing the company portal explicitly
            $Shell = New-Object -ComObject Shell.Application
            $Shell.open("intunemanagementextension://syncapp")
		}
		catch {
            # Should any errors occur, catch them, add them to the error list and write them out immediately
			$errorList += $_
			Write-Error $_
		}
    }
    end {
        # If there have been any errors, write them all out along with a callstack for debugging
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}
