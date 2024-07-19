function Invoke-DeviceDeploymentCleanupCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			Unblock-DeviceShutdown
			Remove-DeviceDeploymentTempData
			THROW "##TODO check mutex is not stuck"
			Disconnect-AzAccount
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