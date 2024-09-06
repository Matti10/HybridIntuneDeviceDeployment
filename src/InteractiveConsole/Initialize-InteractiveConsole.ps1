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
				$action = New-ScheduledTaskAction -Execute "Powershell.exe"

				# Define the trigger - here it's set to run daily at 8:00 AM
				$trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM

				# Define the principal (optional) - specify the user under which the task will run
				$principal = New-ScheduledTaskPrincipal -UserId "defaultuser0" -LogonType Interactive -RunLevel Highest

				# Register the task - this adds the task to Task Scheduler
				Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "MyDailyTask" -Description "This task runs a PowerShell script daily at 8:00 AM"

				# To run the task manually after registration:
				Start-ScheduledTask -TaskName "MyDailyTask"
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