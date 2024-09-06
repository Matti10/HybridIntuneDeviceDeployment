
<#
.Synopsis
This PowerShell function reads a local status file and returns its contents as a JSON object.

.Description
This function takes in a local status file location as input. If the file exists, the function performs a `Get-Content` of the file, which essentially reads the file, and pipes the raw contents through `ConvertFrom-Json_PSVersionSafe` to convert the JSON formatted content to a PowerShell object before returning it. If the file does not exist, the function will return a null value.

This function also supports `ShouldProcess`, which allows you to show what would happen if the function runs, without actually executing it.

.Parameter localStatusFile
The location of the local status file. If this parameter is omitted, the default value from `$DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile` will be used.

.Outputs
This function returns a JSON object if the file exists and is in the correct format. 

Returns a null value if the file does not exist.

.Example
Get-DeviceBuildLocalStatus [-localStatusFile] [<Object>] [<CommonParameters>]

Get-DeviceBuildLocalStatus -localStatusFile "C:\Users\User\Documents\status.json"

.Notes

- If there is any error while executing the function, the errors will be stored in `$errorList` array. At the end of the function, if `$errorList` is not empty, it will write out all errors with `Write-Error` and then stop the script with `-ErrorAction Stop`. 

#>
function Get-DeviceBuildLocalStatus {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $localStatusFile = $DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile
    )

    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                # read local status file
                if (Test-Path -Path $localStatusFile) {
                    return Get-Content -Path $localStatusFile -raw | ConvertFrom-Json_PSVersionSafe
                } else {
                    return $null
                }
            }
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}