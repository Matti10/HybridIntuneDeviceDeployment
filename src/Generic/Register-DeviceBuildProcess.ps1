function Register-DeviceBuildProcess {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[string]
		$runPath = $DeviceDeploymentDefaultConfig.Generic.RunRegistryPath,

		[Parameter(Mandatory)]
		[string]
		$psExecPath,

		[Parameter(Mandatory)]
		[string]
		$BuildProcessPath

	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			try {
				& $psExecPath -i -s powershell "Read-Host"

				New-ItemProperty -Path $runPath -Name "BuildProcess" -Value "$psExecPath -i -s powershell `"Import-Module TriCare-Common; Import-Module TriCare-DeviceDeployment; . '$BuildProcessPath'`""
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