
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
        $shiftF10Path = "$($DeviceDeploymentDefaultConfig.Generic.BuildModulePath)\$($DeviceDeploymentDefaultConfig.Generic.shiftF10RelativePath)",

        [Parameter()]
        [string]
        $completedBuildState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.completedState.message,

        [Parameter()]
        [int]
        $buildProcessWaitTime = $DeviceDeploymentDefaultConfig.Generic.BuildProcessWaitSeconds,

        [Parameter()]
        [int]
        $waitInterval = 30

    )

    # Beginning of the block, initializing an array to collect any potential errors during execution
    begin {
        $errorList = @()
    }

    process {
        # Check host
        if ($PSCmdlet.ShouldProcess("$(hostname)")) {
            try {

                # & $serviceUIPath "C:\windows\System32\WindowsPowerShell\v1.0\powershell.exe" -command ". '$BuildProcessPath'"

                $secondsWaited = 0
                while ($secondsWaited -le $buildProcessWaitTime) {
                    # wait for interactive script to complete - this stops OOBE terminating
                    Write-Verbose "Waiting for Interactive Script Completion"
                    
                    Start-Sleep -Seconds $waitInterval
                    $secondsWaited += $waitInterval
    
                    $buildInfo = Get-DeviceBuildLocalStatus
                    if ($null -ne $buildInfo) {
                        if ($buildInfo.buildState -eq $completedBuildState) {
                            Write-Verbose "Build Process Compelted, letting script finish"
                            return
                        }
                    }
                }
                Write-Verbose "Build Process has timed out ($secondsWaited/$buildProcessWaitTime). letting script finish"
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