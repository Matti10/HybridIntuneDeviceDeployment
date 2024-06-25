function Block-DeviceShutdown {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]$jobName = $DeviceDeploymentDefaultConfig.shutdownListener.jobName,

		[Parameter()]
		[int]$waitSeconds = $DeviceDeploymentDefaultConfig.shutdownListener.waitSeconds
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			# Start Job to Cancel pending shutdowns 
			return Start-Job -Name $jobName -ScriptBlock {
				Start-Transcript -Path "C:\Intune_Setup\Logs\$fileName-$timestamp-$jobName.txt"
				while ($true)
				{
					try {
						shutdown -a
					}
					catch {
						$_
					}
					Start-Sleep -Seconds $waitSeconds
				}    
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}