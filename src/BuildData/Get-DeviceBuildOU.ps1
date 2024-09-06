
# Documentation
<#
.SYNOPSIS
This PowerShell script defines a function named `Get-DeviceBuildOU` that calculates the Organizational Unit (OU) for a given device build and facility object. It is part of a larger system, potentially for managing devices within an IT network. 

.NOTES
During the 'process' block, the function will:
- Form the `baseOU` from the build's OU and the facility's location and department properties.
- Then, it will fix any ",," (double comma) left in the `baseOU`.
- If an error occurs during this process, it would be caught, and the error message would be written on the host.

In the 'end' block, it will throw an error if there were any errors during the 'process' block. 

This function supports ShouldProcess, which enables you to perform 'what if' runs to verify what the function will do before any changes are made. 

.PARAMETER build
A mandatory parameter that accepts a build object.
.PARAMETER facility
A mandatory parameter that accepts a facility object.
.PARAMETER baseOU
An optional parameter that, if not specified, will be retrieved from a predefined configuration `$DeviceDeploymentDefaultConfig.Generic.DeviceOUScope`.

.EXAMPLE
Get-DeviceBuildOU -build $myBuild -facility $myFacility -baseOU $myBaseOU
#>

function Get-DeviceBuildOU {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [Object]$build,

        [Parameter(Mandatory)]
        [Object]$facility,

        [Parameter()]
        $baseOU = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope
    )
    # Initialisation of error list, which will hold any errors that occur during the function execution.
    begin {
        $errorList = @()
    }
    # Begins the process of resolving OU from the facility and build.
    process {
        # If ShouldProcess returns true, the enclosed code will execute.
        if ($PSCmdlet.ShouldProcess("$build & $facility")) {
            try {
                # Forms the baseOU from the build's OU, facility's location and department.
                # Initialises baseOU with the build's OU.
                $baseOU = "$($build.OU),$baseOU"
                $baseOU = "$($facility.location),$(if($build.hasDepartment){$facility.dept}),$baseOU"
            
                # Fixes any ",," (double comma) in the baseOU.
                while ($baseOU -like "*,,*") {
                    $baseOU = $baseOU -replace ",,", ","
                }
                return $baseOU
            }
            # If an error occurs, the error is caught and written to the host.
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }
    # If there were any errors during the process block, it writes those errors to the host.
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}
