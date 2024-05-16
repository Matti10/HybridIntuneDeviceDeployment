function Block-DeviceShutdown {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		$API_Key
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($identity)) {
			# ---------------------------------------------- Start Job to Cancel pending shutdowns ----------------------------------------------
			return Start-Job -ScriptBlock {
				Start-Transcript -Path "C:\Intune_Setup\Logs\$fileName-$timestamp-ShutdownListener.txt"
				while ($true)
				{
					try {
						shutdown -a
					}
					catch {
						$_
					}
					Start-Sleep -Seconds 30
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