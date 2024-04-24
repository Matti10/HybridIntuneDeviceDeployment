function Invoke-CompnayPortalSync {
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
				$Shell = New-Object -ComObject Shell.Application
				$Shell.open("intunemanagementextension://syncapp")
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