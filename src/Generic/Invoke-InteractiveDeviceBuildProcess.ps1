
function Invoke-InteractiveDeviceBuildProcess {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # This parameter is mandatory and denotes the path to the PowerShell script for the build process.
        [Parameter(Mandatory)]
        [string]
        $BuildProcessPath,
        # This parameter is mandatory and denotes the path to PsExec
        [Parameter()]
        [string]
        $serviceUIPath = "$($DeviceDeploymentDefaultConfig.Generic.BuildModulePath)\$($DeviceDeploymentDefaultConfig.Generic.serviceUIRelativePath)",

        [Parameter()]
        [string]
        $shiftF10Path = "$($DeviceDeploymentDefaultConfig.Generic.BuildModulePath)\$($DeviceDeploymentDefaultConfig.Generic.shiftF10RelativePath)"

    )

    # Beginning of the block, initializing an array to collect any potential errors during execution
    begin {
        $errorList = @()
    }

    process {
        # Check host
        if ($PSCmdlet.ShouldProcess("$(hostname)")) {
            try {

                & $serviceUIPath -session:1 "powershell.exe" -ExecutionPolicy Bypass -NoProfile -File "`"$BuildProcessPath`""
            }
            # Catch block to capture any errors that might occur and add them to the error array
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }

    # At the end of the function check if any errors occurred and write them out
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }
}