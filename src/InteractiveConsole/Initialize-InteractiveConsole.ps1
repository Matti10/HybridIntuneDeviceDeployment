function Initialize-InteractiveConsole {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("Getting Config")) {
			try {


				# Define the action - in this case, running a PowerShell script
				$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Verbose:$VerbosePreference

				# Define the trigger - here it's set to run daily at 8:00 AM
				$trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM -Verbose:$VerbosePreference

				# Define the principal (optional) - specify the user under which the task will run
				$principal = New-ScheduledTaskPrincipal -UserId "defaultuser0" -LogonType Interactive -RunLevel Highest -Verbose:$VerbosePreference

				# Register the task - this adds the task to Task Scheduler
				Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "MyDailyTask" -Description "This task runs a PowerShell script daily at 8:00 AM" -Verbose:$VerbosePreference

				# To run the task manually after registration:
				Start-ScheduledTask -TaskName "MyDailyTask" -Verbose:$VerbosePreference
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