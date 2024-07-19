function Invoke-GPUpdate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[string]$runRegistryPath = $DeviceDeploymentDefaultConfig.Generic.RunOnceRegistryPath,

		[int]$waitTime = 60
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("$(hostname)")) {
				#run gpupdate and wait up to a minute before moving on
				gpupdate /force /wait:$waitTime
			}
			
			#schedule GPupdates to run again on first login (just to be sure)
			New-ItemProperty -Name "GPUpdate" -Path $runRegistryPath -Value "gpupdate /force /wait:0" -Force -WhatIf:$WhatIfPreference
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}