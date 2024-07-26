function Get-DeviceBuildLocalStatus {
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
                if (Test-Path -Path $localStatusFile) {
                    return Get-Content -Path $localStatusFile -raw | ConvertFrom-Json_PSVersionSafe
                } else {
                    return $null
                }
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