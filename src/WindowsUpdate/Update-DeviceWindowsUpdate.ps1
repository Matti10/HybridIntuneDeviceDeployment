function Update-DeviceWindowsUpdate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			try {
				Install-WindowsUpdate -Install -IgnoreReboot -AcceptAll -recurseCycle 2 -verbose:$VerbosePreference
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