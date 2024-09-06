
<# Documentation
.SYNOPSIS
Unblocks the device shutdown by stopping the shutdown blocker job.

.DESCRIPTION
The Unblock-DeviceShutdown function stops the shutdown blocker job. The function takes the `$jobName` parameter that is used to get the shutdown blocker job by its name. If the function runs into any errors, it compiles an error list and throws it at the end.

.PARAMETER jobName
Represents the name of the shutdown blocker job. Its default value is provided by `$DeviceDeploymentDefaultConfig.shutdownListener.jobName`.

.EXAMPLE
Unblock-DeviceShutdown -jobName 'Job1'
In this example, the function will stop the job named 'Job1'.

.INPUTS
None. You cannot pipe input to this function.

.OUTPUTS
None. This function does not return any output.

.NOTES
The CmdletBinding attribute in this function modifies the function to behave more like a cmdlet. The SupportsShouldProcess parameter provides a built-in mechanism for the common design patterns of WhatIf and Confirm.

#>
function Unblock-DeviceShutdown {
    [CmdletBinding(SupportsShouldProcess = $true)] # enable the function to support the WhatIf and Confirm parameters.
    param (
        [Parameter()]  
        [string]$jobName = $DeviceDeploymentDefaultConfig.shutdownListener.jobName  # Default job name from configuration.
    )

    begin {  # Begin block for initializing the required prerequisites.
        $errorList = @()
    }

    process {  
        if ($PSCmdlet.ShouldProcess("$(hostname)")) {  # This conditional check is here to prevent unwanted changes.
            # The following line stops the named job.
            Get-Job -Name $jobName | Stop-Job  # Fetches the job with the specified job name and stops it.
        }
    }

    end {
        if ($errorList.count -ne 0) {  # If there are any errors,
            # The following line will write all the errors to the console.
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }    
}
# The function does not return any output or receive any piped input. If there are any errors during execution, the function will throw an error and stop the execution with needed error information printed.