
# Documentation
<#
.SYNOPSIS
A PowerShell function that renames a computer based on the buildInfo.AssetID provided.

.DESCRIPTION
The Set-DeviceName function renames a computer's name to match the buildInfo.AssetID provided. If the hostname already
matches the asset ID, no action will be taken. If any error occurs during the renaming process, it will be 
thrown and added to an error list which will be returned at the end of the function execution.

.PARAMETER buildInfo.AssetID
This is a mandatory parameter, which is used as the new name for the computer.

.EXAMPLE
Set-DeviceName -AssetID 'NEW-COMPUTER-1234'
Above example depicts how to use Set-DeviceName function to rename the computer with the name 'NEW-COMPUTER-1234'

.INPUTS
String. You can pipeline a string containing the new name for the computer.

.OUTPUTS
None. This cmdlet does not return anything.

.LINK
Rename-Computer: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/rename-computer
#>

function Set-DeviceName {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	
		# A mandatory string parameter used as new computer name
		[Parameter(Mandatory)]
		$buildInfo

	)

	begin {
		# Initializes the error list
		$errorList = @()
	}
	process {
		# Checks if proposed computer rename should happen using $buildInfo.AssetID
		if ($PSCmdlet.ShouldProcess($buildInfo.AssetID)) {
			try {
				# Renames computer only if hostname doesn't already match buildInfo.AssetID
				if ("$(hostname)" -ne $buildInfo.AssetID) {
					Rename-Computer -NewName $buildInfo.AssetID -Confirm:$false -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Force -ErrorAction Stop
				}
			}
			catch {
				# On caught error, adds it to error list and writes error
				$errorList += $_
				New-BuildProcessError -errorObj $_ -message "Device Rename has failed!! Please rename manually :)" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
				
				Write-Error $_
			}
		}
	}
	end {
		# If there are errors, writes them out and stops execution
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}