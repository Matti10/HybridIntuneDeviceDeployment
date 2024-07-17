function Remove-DeviceOfficeInstall {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $officeInstallerConfig = $DeviceDeploymentDefaultConfig.Bloatware.Office.OfficeInstallerConfigPath,

		[Parameter()]
		$officeDeploymentToolPath = $DeviceDeploymentDefaultConfig.Bloatware.Office.ODTPath
		
    )

    begin {
        $errorList = @()
    }
    process {
		try {
			if ($PSCmdlet.ShouldProcess("$(hostname)")) {
				Start-Process -FilePath $officeDeploymentToolPath -ArgumentList "/configure `"$officeInstallerConfig`"" -wait
			}
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction "Continue"
        }
    }	
}