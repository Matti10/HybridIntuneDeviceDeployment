
# Documentation
# FUNCTION NAME: Invoke-DeviceDellCommandUpdateUpdates
<#
.SYNOPSIS
This function updates Dell Command Updates which is a Dell software utility responsible for updating Dell computer software.

.DESCRIPTION
The Invoke-DeviceDellCommandUpdateUpdates function is used to scan for Dell software updates and apply them if they are available. This function is only applicable to Dell machines that have the Dell Command Update utility installed. If the function is run on a machine that doesn't have the utility installed, it will output a verbose message indicating that the machine probably isn�t a Dell.

.PARAMETER softwareLocations
Specify the locations from which to install the software. The default is $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations.

.EXAMPLE
Invoke-DeviceDellCommandUpdateUpdates

In this example, Dell Command Update software is being updated from the default software locations specfied in $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations.

.INPUTS 
None

.OUTPUTS
None

.NOTES
Ensure that Dell Command Update is installed on the device before running this function. 

.LINK
[# (Link to more information about this function or related resources.)
#>

function Invoke-DeviceDellCommandUpdateUpdates {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $softwareLocations = $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations,

        [Parameter()]
        $buildInfo = ""
    )
    begin {
        # Initialize an array to hold any errors that occur during execution
        $errorList = @()
    }
    process {
		try {
            # Check if Dell Command Update is present on the device
            $commandUpdatePath = Test-DeviceDellCommandUpdate
            if ($commandUpdatePath -ne $false) {
                # Print message indicating that the Dell Command Update is running
                Write-Verbose "Running Dell Command Update Software Updates"

                # Scan for software updates
                & "$commandUpdatePath" /scan "$(if($VerbosePreference -eq "SilentlyContinue") {"-silent"})"

                # Apply found software updates
                & "$commandUpdatePath" /applyUpdates "$(if($VerbosePreference -eq "SilentlyContinue") {"-silent"})"
            } 
            else {
                # Print message indicating that Dell Command Update is not installed
                Write-Verbose "Device doesn't have Dell command update installed (probably because it isnt a dell)"
            }
		}
		catch {
            # Catch any errors and add them to the error list
			$errorList += $_
            New-BuildProcessError -errorObj $_ -message "Dell Command Update experinced errors. Please run manually" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
			Write-Error $_
		}
    }
    end {
        # If there are any errors in the error list, halt the script and print the errors
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}
