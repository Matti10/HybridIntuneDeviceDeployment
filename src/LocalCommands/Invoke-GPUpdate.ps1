
# Documentation
<#
.DESCRIPTION
The `Invoke-GPUpdate` function is designed to enforce Group Policy updates on a device.
Given a `waitTime` which is set by default to 60 seconds, it will try to enforce Group Policy updates at the device level using the GPUpdate utility available on Windows devices. 
If there was an interruption or the operation was not successful, the Group Policy updates will be enforced again on the system start.

.PARAMETER runRegistryPath
This parameter refers to the registry path where you'd like the Group Policy update to be run on system start.
The default value is given by $DeviceDeploymentDefaultConfig.Generic.RunOnceRegistryPath.

.PARAMETER waitTime
Specifies the time, in seconds, to wait for Group Policy processing to finish before being returned to the command prompt. 
The default value is 60 seconds.

.EXAMPLE
Invoke-GPUpdate -waitTime 120 -runRegistryPath "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
This command enforces a Group Policy update and waits for 120 seconds before moving on to the next task. 
If there was an interruption, the Group Policy updates will be enforced again on the system start, which is specified in the provided registry path.

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS 
Error records about failed GPUpdate operations.

.NOTES
The SupportsShouldProcess parameter in CmdletBinding allows you to 
use the -WhatIf and -Confirm parameters to control the running of the command.
#>
function Invoke-GPUpdate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string]$runRegistryPath = $DeviceDeploymentDefaultConfig.Generic.RunOnceRegistryPath,
		[int]$waitTime = 60
	)

	begin {
		# Initialize an empty list to store any errors
		$errorList = @()
	}

	process {
		try {
			#Check if we should run the gpupdate
			if ($PSCmdlet.ShouldProcess("$(hostname)")) {
				#Run gpupdate, and wait up to specified waitTime in seconds before moving on
				gpupdate /force /wait:$waitTime
			}
			
			# Schedule gpupdate to run again in case of system login
			New-ItemProperty -Name "GPUpdate" -Path $runRegistryPath -Value "gpupdate /force /wait:0" -Force -WhatIf:$WhatIfPreference
		}

		catch {
			# Add the error to the list and write it
			$errorList += $_
            New-BuildProcessError -errorObj $_ -message "GPUpdate experinced errors. Please run manually" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue"
			Write-Error $_
		}
	}

	end {
		# If there are errors, stop the process and give information about the errors
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}