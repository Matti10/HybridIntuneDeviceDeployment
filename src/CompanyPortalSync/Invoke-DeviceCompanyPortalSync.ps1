function Invoke-DeviceCompanyPortalSync {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $syncTaskName = $DeviceDeploymentDefaultConfig.CompanyPortalSync.syncTaskName

    )

    begin {
        $errorList = @()
    }
    process {
		try {
			$syncTask = Get-ScheduledTask | Where-Object {$_.TaskName -eq $syncTaskName} 

			if ($null -eq $syncTask) {
				Write-Verbose "The Intune sync scheduled task doesn't exist, possibly due to company portal not being installed"
			} else {
				$syncTask | Start-ScheduledTask -whatIf:$WhatIfPreference -Verbose:$VerbosePreference
			}
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
        }
    }	
}