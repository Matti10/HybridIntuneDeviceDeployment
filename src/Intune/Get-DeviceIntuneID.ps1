

## Comment Based Help Documentation

<#
.SYNOPSIS
This function returns the Intune ID of the device from the registry.

.DESCRIPTION
The Get-DeviceIntuneID cmdlet retrieves the Intune ID from the  
registry using the provided registry path and key name. 

.PARAMETER intuneIDRegPath
Specifies the path of the registry where the Intune ID is stored. 
The default value is retrieved from the $DeviceDeploymentDefaultConfig.Intune.IntuneIDRegPath property.

.PARAMETER intuneIDRegKey
Specifies the name of the registry key where the Intune ID is stored. 
The default value is retrieved from the $DeviceDeploymentDefaultConfig.Intune.IntuneIDRegKey property.

.EXAMPLE
Get-DeviceIntuneID

This command retrieves the Intune ID from the default registry path and key.

.INPUTS
None.

.OUTPUTS
The cmdlet returns the Intune device ID stored in the specified registry path and key.

.NOTES
If the cmdlet encounters any errors while retrieving the Intune ID, it will record the errors into an error list and write it out at the end of processing.
#>

function Get-DeviceIntuneID {
    [CmdletBinding(SupportsShouldProcess = $true)] 
    # The CmdletBinding attribute allows this function to function like a cmdlet and use the common parameters Jobs, Verbose, ErrorAction, ErrorVariable, etc.
    param (
        [Parameter()]
        # Registry path to retrieve the Intune ID.
        $intuneIDRegPath = $DeviceDeploymentDefaultConfig.Intune.IntuneIDRegPath,

        [Parameter()]
        # Registry key name to retrieve the Intune ID.
        $intuneIDRegKey = $DeviceDeploymentDefaultConfig.Intune.IntuneIDRegKey
    )

    begin {
        # Define an empty array to store any errors that may occur.
        $errorList = @()
    }

    process {
        # Checking whether the function should continue processing.
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                # Try to return the Intune ID stored in Registry.
                return Get-ItemPropertyValue -Path $intuneIDRegPath -Name $intuneIDRegKey -Verbose:$VerbosePreference
            }
            catch {
                # In case of errors, record the error and write it.
                $errorList += $_
                Write-Error $_
            }
        }
    }

    end {
        # If there were errors, write an error message with details of the errors and stop the execution.
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }
}