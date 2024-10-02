
<#
    .SYNOPSIS
        This function writes the build status of a device to a local status file and also update it to any other location (like a server or cloud etc.). If any error occurs during this process, it logs all the errors.

    .DESCRIPTION
        The Write-DeviceBuildStatus function takes in a mandatory buildInfo parameter and an optional localStatusFile parameter. It writes the build information in JSON format to a local status file and also calls the Write-DeviceBuildTicket function to update the status somewhere else (not defined in function). The error statements, if any, are saved in an array and are written after the function execution.

    .PARAMETER buildInfo
        A mandatory parameter that represents the information related to the build status of the device.
    
    .PARAMETER localStatusFile
        The local file where the build status will be written. It defaults to the value of the DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile if no value is provided.

    .EXAMPLE
        Write-DeviceBuildStatus -buildInfo $buildInfo -localStatusFile $statusFile

        Description:
        Writes the buildInfo to the $statusFile and also call another function to update it somewhere else.
#>

function Write-DeviceBuildStatus {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # A mandatory parameter that represents the information related to the build status of the device.
        [Parameter(Mandatory)]
        $buildInfo,

        # An optional parameter for specifing the local file where the build status will be written. The default value is the value of the DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile.
        [Parameter()]
        $localStatusFile = $DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile
    )

    begin {
        # Initializing error list
        $errorList = @()
    }
    process {
        # Check if the operation should be processed
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                # Write the build info in JSON format to the local status file
                Set-Content -Path $localStatusFile -Value ($buildInfo | ConvertTo-Json) -Verbose:$VerbosePreference
                
                # Write the build info to the device build ticket
                Write-DeviceBuildTicket -buildInfo $buildInfo -Verbose:$VerbosePreference
            }
            catch {
                # Catch error and add it to the error list
                $errorList += $_
                
            }
        }
    }
    end {
        # Throw an error if there were errors during the script execution
        if ($errorList.count -ne 0) {
			$errorList | ForEach-Object {
                New-BuildProcessError -errorObj $_ -message "Error Communicating with Fresh Ticket. Matt may be able to manually fix this for you. If not, Please check device exists in fresh and is setup as per build documentation. Then wipe the device and restart" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
            }
        }
    }	
}