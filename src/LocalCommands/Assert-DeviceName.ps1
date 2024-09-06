
<#
.SYNOPSIS
A Powershell function for checking if the hostname matches the provided AssetID and, if required, attempts to change it.

.DESCRIPTION
The Assert-DeviceName function checks the hostname of the computer against the provided AssetID. 

If the hostname and AssetID do not match, there are two possibilities determined by the optional $retry switch:

    - If the $retry switch is not used, the function raises an exception and prompts the user to manually rename the computer.

    - If the $retry switch is used, the function attempts to change the hostname to the AssetID using the Set-DeviceName function.

If the hostname and AssetID match, the function prints out the current hostname and AssetID.

.PARAMETER AssetID
A string representing the AssetID of the computer. This parameter is mandatory.

.PARAMETER retry 
A switch parameter that specifies whether the function should attempt to change the hostname to match the AssetID.

.EXAMPLE
Assert-DeviceName -AssetID "PC12345" -retry

This command checks if the hostname matches AssetID "PC12345". If they don't match, it attempts to change the hostname to "PC12345".

#>

function Assert-DeviceName {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Parameter indicating the AssetID of the computer.
        [Parameter(Mandatory)]
        [string]
        $AssetID,

        # Switch parameter to indicate whether to retry the hostname change.
        [Parameter()]
        [switch]
        $retry
    )

    # Begin block initializes the error list.
    begin {
        $errorList = @()
    }

    process {
        try {
            # Check if hostname matches AssetID
            if ("$(hostname)" -ne $AssetID) {
                Write-Verbose "Computer Name change failed. Current name is $(hostname) asset id is $AssetID"

                # If retry switch is on, try to change hostname.
                # Else, raise an error and ask for manual intervention
                if ($retry) {
                    Set-DeviceName -AssetId $AssetID
                } else {
                    Write-Error "Renaming Computer failed. Current name is $(hostname) asset id is $AssetID. Please rename manually" -ErrorAction Stop
                }
            } else {
                Write-Verbose "Computer Name change correct. Current name is $(hostname) asset id is $AssetID"
            }
        }
        # Catch block to handle errors
        catch {
            $errorList += $_
            Write-Error $_
        }
    }

    # End block to throw an error if there were any errors throughout the process.
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }   
}