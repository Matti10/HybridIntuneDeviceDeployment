
function Invoke-BuildProcessRetry {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Specifies the modules that should be imported.
        [Parameter()]
		[string]
        $message = "",

        [Parameter()]
		$messageTemplates = $DeviceDeploymentDefaultConfig.DeviceUserInteraction.messages,

        [Parameter()]
        $resultCorrelation = $DeviceDeploymentDefaultConfig.DeviceUserInteraction.results
    )

    # Begin block of function: Initialize an empty array to contain all errors.
    begin {
        $errorList = @()
    }

    # Process block of function: Iterate over each module and attempt to import it.
    process {
        try {
            Write-Verbose -Message "Initiating Build Process Retry"
            $result = Show-DeviceUserMessage -message $messageTemplates.retryBuildProcess.message -title $messageTemplates.retryBuildProcess.title -wait -messageBoxConfigCode $messageTemplates.retryBuildProcess.messageBoxConfiguration -placeholderValue $message

            switch ($result) {
                $resultCorrelation.Retry {
                    #restart build process
                    Write-Verbose "Build process is being restarted"
                    if ($PSCmdlet.ShouldProcess("Retry")) {
                        Invoke-InteractiveDeviceBuildProcess -BuildProcessPath "$($DeviceDeploymentDefaultConfig.Generic.BuildModulePath)\$($DeviceDeploymentDefaultConfig.Generic.BuildProcessRelativePath)"
                    } else {
                        return "Path called: $($DeviceDeploymentDefaultConfig.Generic.BuildModulePath)$($DeviceDeploymentDefaultConfig.Generic.BuildProcessRelativePath)"
                    }
                }
                $resultCorrelation.Abort {
                    # wipe the machine
                    Write-Verbose "Machine is wiping"
                    if ($PSCmdlet.ShouldProcess("Wipe")) {
                        & systemreset.exe
                    } else {
                        return "running systemreset.exe"
                    }
                }
                $resultCorrelation.Ignore {
                    # do nothing
                    Write-Verbose "Continuing to windows"
                    if ($PSCmdlet.ShouldProcess("Wipe")) {
                        return
                    } else {
                        return "Continuing to windows"
                    }
                }
            }
        }
        catch {
            $errorList += $_ # Collects encountered error in this block.
            Write-Error $_ # Writes out caught error.
        }
    }

    # End block of function: Notify of any import errors that occurred during process.
    end {
        if ($errorList.count -ne 0) {
            # Outputs an error message detailing all import errors that occurred during execution.
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }
}