
# Documentation
<#
.SYNOPSIS
A PowerShell function to find correlation details about a device

.DESCRIPTION
The Find-DeviceCorrelationInfo function is used to get the details about a specific device correlation. The function takes build, facility and other optional parameters. The function returns correlation details about the device in the form of a custom PowerShell object.

.PARAMETER build
A mandatory string parameter. This parameter is used to specify build details.

.PARAMETER facility
A mandatory string parameter. This parameter is used to specify the device facility details.

.PARAMETER baseOU
An optional parameter. This parameter is used to specify the base ou. If not given, its value will be set to $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope by default.

.PARAMETER buildTypes
An optional parameter. This parameter is used to specify the build types. If not given, its value will be set to $DeviceDeploymentDefaultConfig.Deployment.buildTypeCorrelation by default.

.PARAMETER facilities
An optional parameter. This parameter is used to specify the facilities detail. If not given, its value will be set to $DeviceDeploymentDefaultConfig.Deployment.locationCorrelation by default.

.EXAMPLE
Find-DeviceCorrelationInfo -build "Build1234" -facility "Facility1"

This command will return correlation details about the "Build1234" from "Facility1".

.NOTES
Written by: YOUR NAME HERE
Requires: PowerShell v5.0 (for MyClass)
#>

function Find-DeviceCorrelationInfo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # A mandatory parameter that specifies the build
        [Parameter(Mandatory)]
        [string]$build,

        # A mandatory parameter that specifies the facility
        [Parameter(Mandatory)]
        [string]$facility,

        # An optional parameter that specifies the base OU
        [Parameter()]
        $baseOU = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope,

        # An optional parameter that specifies the build types
        [Parameter()]
        $buildTypes = $DeviceDeploymentDefaultConfig.Deployment.buildTypeCorrelation,

        # An optional parameter that specifies the facilities
        [Parameter()]
        $facilities = $DeviceDeploymentDefaultConfig.Deployment.locationCorrelation
    )

    # Initialize an empty error list
    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("$build & $facility")) {
            try {
                # Initialize the build and facility correlation as null
                $buildCorrelation = $null
                $facilityCorrelation = $null

                # Iterate over all build types and find the matching one with supplied build
                foreach ($buildType in $buildTypes) {
                    if ($build -eq $buildType.buildType) {
                        $buildCorrelation = $buildType
                        break
                    }
                }

                # Iterate over all facilities and find the matching one with supplied facility
                foreach ($location in $facilities) {
                    if ($facility -eq $location.freshID) {
                        $facilityCorrelation = $location
                    }
                }

                # If either build or facility correlation is null, throw an error
                if ($null -eq $buildCorrelation -or $null -eq $facilityCorrelation) {
                    Write-Error "No correlation info could be found for either the build ($build | $buildCorrelation) and/or facility ($facility | $facilityCorrelation)"
                }
            
                # Return a custom object with correlation details
                return [PSCustomObject]@{
                    buildCorrelation    = $buildCorrelation
                    facilityCorrelation = $facilityCorrelation
                }
            }
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }
    end {
        # If there were any errors, print all of them and throw an error
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}

#This PowerShell function, `Find-DeviceCorrelationInfo`, retrieves correlation information about a device as specified by given parameters. It ultimately outputs this information as a custom object, including build and facility correlations if available. If any error occurs during the process, it prints the error and stops the execution. This function requires PowerShell v5.0.