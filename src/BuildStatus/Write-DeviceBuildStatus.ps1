function Write-DeviceBuildStatus {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        $buildInfo,

        [Parameter()]
        $localStatusFile = $DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile
    )

    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                # Write to local status file
                Set-Content -Path $localStatusFile -Value ($buildInfo | ConvertTo-JSON) -Verbose:$VerbosePreference
                
                # Write status to fresh
                Write-DeviceBuildTicket -buildInfo $buildInfo -Verbose:$VerbosePreference
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