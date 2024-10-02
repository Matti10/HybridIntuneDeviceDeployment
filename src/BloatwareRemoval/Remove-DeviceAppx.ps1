<#

.Synopsis
This function deploys the Office Removal Process on the targeted device.

.Description
The `Remove-DeviceOfficeInstall` function uses the Office Deployment Tool to remove Microsoft Office installation from a device. If any error occurs during this process, it gets caught and added to an error list. In the end, if the error list has recorded any errors, it will output all errors with the function call stack.


.Parameter officeInstallerConfig
(Parameter): The file path to the XML configuration file required by the Office Deployment Tool for the office removal process. If not provided, by default it fetches the path from `$DeviceDeploymentDefaultConfig.Bloatware.Office.OfficeInstallerConfigPath`.

.Parameter officeDeploymentToolPath
(Parameter): The file path to the Office Deployment Tool executable. If not provided, it fetches the value from `$DeviceDeploymentDefaultConfig.Bloatware.Office.ODTPath`.

.Notes

- Initializes an empty error list.

- Starts a process using the Office Deployment Tool to execute the Office removal process, given the officeInstallerConfig. If the execution raises an error, it will be caught and written to the error list and as an error message.

- If any errors occurred during the process, it writes them as an error message along with the function call stack.

.Example

`Remove-DeviceOfficeInstall -officeInstallerConfig "C:\ExamplePath\Config.xml" -officeDeploymentToolPath "C:\ExamplePath\setup.exe"`

#>
function Remove-DeviceAppx {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Parameter defining the path of the XML Configuration file for the office removal process
        [Parameter()]
        $exemptAppx = $DeviceDeploymentDefaultConfig.Bloatware.AppX.Exempt,

		[Parameter()]
        $buildInfo = ""
    )

    # Beginning of the function initializing an empty array to record errors
    begin {
        $errorList = @()
        $AllAppX = Get-AppXProvisionedPackage -Online 
    }
    process {
		try {
            # Condition to control the office removal process
			if ($PSCmdlet.ShouldProcess("$(hostname)")) {
                # Process to run the office deployment tool with given officeInstallerConfig
                foreach ($AppX in $AllAppX.DisplayName) {
                    if ($AppX -notin $exemptAppx) {
                        Write-Verbose "Removing $AppX"
                        Remove-AppxProvisionedPackage -Online -PackageName $AppX
                    } else {
                        Write-Verbose "$AppX is exempt from removal"
                    }
                }
			}
		}
		catch {
            # In case an error occurs in the process, it gets added to the error list
			$errorList += $_
            New-BuildProcessError -errorObj $_ -message "Office failed to Uninstall, please uninstall manually if required" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue"  -buildInfo $buildInfo
		}
    }
    end {
        # If the error list isn't empty, it will print all the errors
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction "Continue"
        }
    }	
}