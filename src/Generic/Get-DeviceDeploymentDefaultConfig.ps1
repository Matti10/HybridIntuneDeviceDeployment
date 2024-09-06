
# Documentation
<#
.SYNOPSIS
This PowerShell function returns "DeviceDeploymentDefaultConfig" object.

.DESCRIPTION
Get-DeviceDeploymentDefaultConfig is a simple function which retrieves the value of the variable "$DeviceDeploymentDefaultConfig". This function requires no parameters and always returns the current state of $DeviceDeploymentDefaultConfig.


.EXAMPLE
An example to illustrate the usage of Get-DeviceDeploymentDefaultConfig function.

PS C:\> Get-DeviceDeploymentDefaultConfig

This will produce whatever value or state is currently stored in $DeviceDeploymentDefaultConfig.

.INPUTS
None - It does not accept any input as it operates on an internal, global variable.

.OUTPUTS
The function outputs the contents of the global variable: $DeviceDeploymentDefaultConfig.

.NOTES
This function does not affect the state of $DeviceDeploymentDefaultConfig in any way and simply returns the current value/state.
#>
function Get-DeviceDeploymentDefaultConfig {
    # Returns the Device Deployment Default Configuration
    return $DeviceDeploymentDefaultConfig
}
