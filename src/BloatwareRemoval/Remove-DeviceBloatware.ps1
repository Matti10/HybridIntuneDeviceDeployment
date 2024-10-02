
<#
.SYNOPSIS
This function is designed to remove device bloatware using PowerShell. 

.DESCRIPTION
The Remove-DeviceBloatware function is capable of removing specified bloatware installed on a device. This is achieved through software's defined uninstall attributes in the Windows Registry. It also provides error handling and logging capabilities.

.PARAMETER softwareToRemove
This is an array that contains the names of the software to be removed. 

.PARAMETER registryLocations
An array of Windows Registry paths which will be checked for determined bloatware. 

.PARAMETER quietUninstallAttr
Specifies the quiet uninstall string of a software, if it is available in the registry. 

.PARAMETER loudUninstallAttr
Specifies the normal uninstall string of a software, if it is available in the registry. 

.PARAMETER registryRoots
This parameter defines the roots of the registry from which to start the search for the specified software. It defaults to using HKEY_LOCAL_MACHINE (HKLM) and all subkeys of HKEY_USERS.

.EXAMPLE
Remove-DeviceBloatware -softwareToRemove @("ProgramA", "ProgramB") -registryLocations @("Path1", "Path2")

This will attempt to remove ProgramA and ProgramB, looking at the registry keys located in Path1 and Path2.
#>

function Remove-DeviceBloatware {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $softwareToRemove = $DeviceDeploymentDefaultConfig.Bloatware.SoftwareToRemove,

        [Parameter()]
        $registryLocations = $DeviceDeploymentDefaultConfig.Bloatware.registryLocations,

        [Parameter()]
        $quietUninstallAttr = $DeviceDeploymentDefaultConfig.Bloatware.quietUninstallAttr,

        [Parameter()]
        $loudUninstallAttr = $DeviceDeploymentDefaultConfig.Bloatware.loudUninstallAttr,
        
        [Parameter()]
        $registryRoots = @("HKLM:") + (Get-ChildItem -LiteralPath Registry::HKEY_USERS).PSPath,

        [Parameter()]
        $buildInfo = ""
    )

    # List of errors to be reported at the end of the process
    begin {
        $errorList = @()
    }

    process {
        try {
            Remove-DeviceOfficeInstall -Verbose:$VerbosePreference -buildInfo $buildInfo

            # Loop through all defined roots and locations in the registry
            foreach ($registryRoot in $registryRoots) {
                foreach ($registryLocation in $registryLocations) {

                    Write-Verbose "Searching $registryRoot$registryLocation"
                    # Go through each item located at a location in the registry
                    Get-ChildItem -Path "$registryRoot$registryLocation" -ErrorAction "SilentlyContinue" | ForEach-Object {
                        $properties = $_ | Get-ItemProperty
                        # If the item exists
                        if ($null -ne $properties) {
                            # Loop through all the software to remove
                            foreach ($softwareItem in $softwareToRemove) {
                                try {
                                    $members = $properties | Get-Member
                                    # If specific software is found on the device
                                    if ($null -ne $members) {
                                        # If it has a corresponding uninstall string
                                        if ($members.name -contains $softwareItem.searchAttr) {
                                            # If the software matches the conditions
                                            if ($properties."$($softwareItem.searchAttr)" -like $softwareItem.searchString) {
                                                # If there's a quiet uninstall option available
                                                if ($members.name -contains $quietUninstallAttr) {
                                                    Write-Verbose "$quietUninstallAttr found with value $($properties.$quietUninstallAttr)"
                                                    $uninstallString = $properties.$quietUninstallAttr
                                                }
                                                # If there's a normal uninstall option available
                                                elseif ($members.name -contains $loudUninstallAttr) {
                                                    Write-Verbose "$loudUninstallAttr found with value $($properties.$loudUninstallAttr)"
                                                    $uninstallString = $properties.$loudUninstallAttr
                                                }
                                                else {
                                                    Write-Verbose "No uninstall string found for object"
                                                }

                                                $splitUninstallString = $uninstallString.split(" ")

                                                if($null -ne $softwareItem.AddtnUninstallArgs) {
                                                    $args =  @($splitUninstallString[1..-1] + $softwareItem.AddtnUninstallArgs)
                                                } else {
                                                    $args =  @($splitUninstallString[1..-1])
                                                }
                                                
                                                Write-Verbose "Running $($splitUninstallString[0]) with arguments $($args)"
                                                
                                                # Attempt to uninstall the software
                                                try {
                                                    Start-Process -FilePath $splitUninstallString[0] -ArgumentList $args -Verbose:$VerbosePreference -Wait -ErrorAction "Stop"
                                                } catch {
                                                    & "$uninstallString"
                                                }
                                            }
                                        }
                                    } 
                                }
                                # If something goes wrong, report it in console and add to error list
                                catch {
                                    $errorList += $_
                                }
                            }
                        }
                    }
                }
            }
        }
        # If something goes wrong, report it in console and add to error list
        catch {
            $errorList += $_
            
        }
    }
    
    end {
        # Report any errors occurred during the whole process
        if ($errorList.count -ne 0) {
            New-BuildProcessError -errorObj $_ -message "Issues uninstalling Bloatware, please check and manually uninstall" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
        }
    }
}