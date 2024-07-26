function Test-DeviceBuildExecuted {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $localStatusFile = $DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile
    )

    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                # read local status file
				if ($null -eq (Get-DeviceBuildLocalStatus)) {
					return $true
				}

				return $false
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