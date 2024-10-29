
# Documentation
<#

.SYNOPSIS
    The "Get-DeviceBuildGroups" function takes two mandatory objects "$build" and "$facility", and optionally one "$baseOU" parameter then it attempts to combine the "groups" properties of both "$build" and "$facility" objects.

.DESCRIPTION
    The purpose of this function is to create a list that contains the groups from two different objects; "$build" and "$facility". These two objects are required as inputs when calling this function. Additionally, it takes "$baseOU" as an optional parameter. If there is a failure during the process of creating the combined list, the function writes the error in the "$errorList" array. 

.PARAMETER build
    This is a mandatory parameter representing a specific build for a device. It is expected to have a "groups" property.

.PARAMETER facility
    This facility is another mandatory parameter and represents a specific location or environment. It also must contain a "groups" property.

.PARAMETER baseOU
    The baseOU parameter is optional and it presumably contains the scope within the Active Directory Organization Unit intended for device deployment. The parameter has a default value referred from "$DeviceDeploymentDefaultConfig.Generic.DeviceOUScope".

.EXAMPLE
    PS C:\> Get-DeviceBuildGroups -build $buildObj -facility $facilityObj 

    This will return the combination of "groups" information from the "$buildObj" and "$facilityObj".

.INPUTS
    The function takes three inputs:
    - '$build' (mandatory) which is a specific build for a device,
    - '$facility' (mandatory) which represents a specific location or environment,
    - '$baseOU' (optional) which contains OU Scope and has a default value.

.OUTPUTS
    This function outputs a list which includes combined groups from '$build' and '$facility'. If there's an error during the operation, the error will be displayed.

.NOTES 
    Error handling is done through a try-catch block that adds any exceptions to an error list, "$errorList". If this array contains any items at the end of the functions execution (i.e., if there were any errors), it outputs a detailed error message and ends the operation.
    
    The command "Write-Error $_" writes the error message from the catch block to the error output stream.

#>

# Start the script, initialize error list array.
function Get-DeviceBuildGroups {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Define mandatory parameters
        [Parameter(Mandatory)]
        [Object]$build,

        [Parameter(Mandatory)]
        [Object]$facility,

        # Define optional parameters
        [Parameter()]
        $baseOU = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope
    )

    # Begin block executes before processing any input objects
    begin {
        $errorList = @()
    }

    # Process block executes for each input object received from the pipeline
    process {
        if ($PSCmdlet.ShouldProcess("$build & $facility")) {
            try {
                # Return combined groups from build and facility objects
                return $facility.groups + $build.groups
            }
            catch {
                # If any error occur add it to the error list
                $errorList += $_
                Write-Error $_
            }
        }
    }
    
    # End block executes after all input objects have been processed
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }   
}