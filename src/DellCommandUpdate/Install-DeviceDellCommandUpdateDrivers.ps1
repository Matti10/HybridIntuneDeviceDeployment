
# Documentation
<#
.SYNOPSIS
This function is used to install device drivers using Dell Command Update.

.DESCRIPTION
The Install-DeviceDellCommandUpdateDrivers function will utilize Dell Command Update to install device drivers to the targeted machine. This function is specifically designed to work with Dell systems. In case the system does not have the Dell Command Update installed or if it is not a Dell system, a verbose message will be displayed.

.PARAMETER softwareLocations
An optional parameter that takes a list of software installation locations. If none is provided, it will use the DellCommandUpdate installation locations defined in the 'DeviceDeploymentDefaultConfig' configuration.

.EXAMPLE
Install-DeviceDellCommandUpdateDrivers

Executes the function with the default DellCommandUpdate installation locations.

.EXAMPLE
Install-DeviceDellCommandUpdateDrivers -softwareLocations "C:\Software"

Executes the function with a custom software location.

.INPUTS
$softwareLocations 
Path to the directory where the software is installed, it is optional.

.OUTPUTS
None. Errors are written to the error stream.

.NOTES
Before running this function, Dell Command Update must be present on the system. Moreover, the account executing the script requires administrative privileges over the system.

#>

function Install-DeviceDellCommandUpdateDrivers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Parameter definition for the software locations.
        [Parameter()]
        $softwareLocations = $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations,

        [Parameter()]
        $buildInfo = ""
    )
    begin {
        # Initialize error list to empty.
        $errorList = @()
    }
    process {
        try {
            # Test if Dell Command Update is installed.
            $commandUpdatePath = Test-DeviceDellCommandUpdate
            if ($commandUpdatePath -ne $false) {
                # Dell Command Update found, display a verbose message and continue with the update.
                Write-Verbose "Running Dell Command Update Driver Updates"
                # Enable the advancedDriverRestore feature.
                & "$commandUpdatePath" /configure -advancedDriverRestore=enable

                # Install the drivers.
                & "$commandUpdatePath" /driverInstall "$(if($VerbosePreference -eq "SilentlyContinue") {"-silent"})"
            } else {
                # Dell Command Update not found, display a verbose message.
                Write-Verbose "Device doesn't have Dell command update installed (probably because it isn't a dell)"
            }
        }
        catch {
            # In case of an error, add it to the error list and write it to the Error Stream.
            $errorList += $_
        }
    }
    end {
        # If there were any errors, stop the process and display the error details.
        if ($errorList.count -ne 0) {
            New-BuildProcessError -errorObj $_ -message "Dell Command Update experinced errors. Please run manually" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
        }
    }  
}
