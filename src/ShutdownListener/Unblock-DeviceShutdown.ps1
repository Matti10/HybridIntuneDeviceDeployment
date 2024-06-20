function Unblock-DeviceShutdown {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]$jobName = $DeviceDeploymentDefaultConfig.shutdownListener.jobName
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			# stop the shutdown blocker job
			Get-Job -Name $jobName | Stop-Job
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}