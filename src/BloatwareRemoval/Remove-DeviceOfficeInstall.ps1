function Remove-DeviceOfficeInstall {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $officeInstallerConfig = $DeviceDeploymentDefaultConfig.Bloatware.Office.OfficeInstallerConfigPath,

		[Parameter()]
		$officeExeName = $DeviceDeploymentDefaultConfig.Bloatware.Office.officeInstallerName,
		
		[Parameter()]
		$searchRoots = $DeviceDeploymentDefaultConfig.Bloatware.Office.searchRoots
    )

    begin {
        $errorList = @()
    }
    process {
		try {
			foreach ($searchRoot in $searchRoots) {
				Get-ChildItem -recurse -File | Where-Object {$_.FullName -like "*$officeExeName*"} | ForEach-Object {
					Start-Process -FilePath $_.FullName -ArgumentList "/configure $officeInstallerConfig"
					return
				} 
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