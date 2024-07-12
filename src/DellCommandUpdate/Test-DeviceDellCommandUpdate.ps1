function Test-DeviceDellCommandUpdate {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $softwareLocations = $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations

    )

    begin {
        $errorList = @()
    }
    process {
		try {
            Write-Verbose "Searching for Dell Command Update"
			foreach ($location in $softwareLocations) {
				if (Test-Path -path $location) {
					return $location
				}
			}

			return $false
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
        }
    }	
}