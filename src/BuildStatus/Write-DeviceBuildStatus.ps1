
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
                Write-Error $_
            }
        }
    }
    end {
        # Throw an error if there were errors during the script execution
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}