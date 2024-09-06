
<# Documentation
.SYNOPSIS
This PowerShell function checks for the existence of Dell Command Update software on the specified path(s).

.DESCRIPTION
The function uses the Test-Path cmdlet to validate whether the Dell Command Update software exists in the designated software locations or not. If Dell Command Update software is found in any of the provided paths, the function returns the location; otherwise it returns 'false'. 

During the process, any errors encountered are caught, added to an error list, and printed out. If there are errors added to this list, they are displayed and the function execution stops.


.PARAMETER softwareLocations
{optional} An array of locations that the function will check for Dell Command Update. By default uses install locations specified in the `$DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations` if no argument is given

.EXAMPLE
## Example 1
wget
PS C:\> Test-DeviceDellCommandUpdate

This command will check for Dell Command Update software on the paths specified in `$DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations`.

## Example 2
wget
PS C:\> Test-DeviceDellCommandUpdate -softwareLocations C:\Example\Path, D:\Another\Path

This command will check for Dell Command Update software on the paths 'C:\Example\Path' and 'D:\Another\Path'.

.NOTES
In 'process' block, the function searches each provided location for Dell Command Update software, and if found it immediately stops searching and returns the location.

In 'end' block, the function checks if there are any errors stored in the `$errorList` by checking its count. If count is not 0, it throws an error with a detailed description of what went wrong and stops the execution of the function.

#>
function Test-DeviceDellCommandUpdate {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $softwareLocations = $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations

    )

    begin {
        $errorList = @()
    }
    process {
		try {
            Write-Verbose "Searching for Dell Command Update"
			foreach ($location in $softwareLocations) {
				if (Test-Path -path $location) {
					return $location
				}
			}

			return $false
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}