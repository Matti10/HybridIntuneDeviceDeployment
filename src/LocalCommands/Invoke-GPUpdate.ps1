function Invoke-GPUpdate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string]$runRegistryPath = $DeviceDeploymentDefaultConfig.Generic.RunOnceRegistryPath
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($identity)) {
			try {
				#run gpupdate and wait up to a minute before moving on
				gpupdate /force /wait 60
				
				#schedule GPupdates to run again on first login (just to be sure)
				New-ItemProperty -Name "GPUpdate" -Path $runRegistryPath -Value "gpupdate /force /wait 0" -Force
			}
			catch {
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}