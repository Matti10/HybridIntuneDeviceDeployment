
# Documentation
<#
.SYNOPSIS
    This function imports a specified set of PowerShell modules.

.DESCRIPTION
    The function `Import-DeviceBuildModules` attempts to import a list of modules specified in its parameters or defaults to a list defined in the `DeviceDeploymentDefaultConfig.Dependencies` configuration.

    If there are problems importing any of the modules, the errors are collected and outputted at the end of the function's execution.

.PARAMETER modules
    The list of modules to import. If no parameter is passed in, the function will default to using `DeviceDeploymentDefaultConfig.Dependencies` for the list of modules.

.EXAMPLE
    Import-DeviceBuildModules -modules @('module1','module2')

    Attempts to import 'module1' and 'module2'.
#>
function Import-DeviceBuildModules {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Specifies the modules that should be imported.
        $modules = $DeviceDeploymentDefaultConfig.Dependencies
    )

    # Begin block of function: Initialize an empty array to contain all errors.
    begin {
        $errorList = @()
    }

    # Process block of function: Iterate over each module and attempt to import it.
    process {
        if ($PSCmdlet.ShouldProcess("Importing Modules")) {
            try {
                foreach ($module in $modules) {
                    Write-Verbose "Importing $module" # Informative message for each module being imported.
                    Import-Module $module # Import function from PSmodule.
                }
            }
            catch {
                $errorList += $_ # Collects encountered error in this block.
                Write-Error $_ # Writes out caught error.
            }
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