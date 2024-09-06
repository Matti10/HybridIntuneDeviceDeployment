
<#
.SYNOPSIS
This function checks if the AssetID Mutex of a device is currently accessed or not.

.DESCRIPTION
The Test-DeviceAssetIDMutex function uses on the Get-DeviceAssetIDMutex method to return the currently accessed status of the AssetID Mutex of a device. 
If this method throws an exception, it'll be catched and an error message will be returned. 
The errors are collected in $errorList, 
if this list count is not zero, an error would be written which stops the error action.

.PARAMETER
The function does not take any parameters.

.EXAMPLE
Test-DeviceAssetIDMutex

This will return whether the AssetID Mutex of a device is currently accessed or not.
#>

function Test-DeviceAssetIDMutex {
	# CmdletBinding attribute is used to make a function act like a cmdlet.
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	)

	# The begin block is run before the process block. It's used here to initialize the error list.
	begin {
		$errorList = @()
	}
	# The process block is run for each input. Here it checks if the function should perform its action or not.
	process {
		# Determines whether the cmdlet should perform its processing. 
		# This allows the user to observe what would happen if they ran the function.  
		if ($PSCmdlet.ShouldProcess("AssetID Mutex")) {
			try {
				# If there's no exception during the invocation of Get-DeviceAssetIDMutex, the currently accessed status will be returned,
				return (Get-DeviceAssetIDMutex).currentlyaccessed
			}
			catch {
				# If there's any exception during the invocation of Get-DeviceAssetIDMutex, the error will be stored in the error list and also written right away.
				$errorList += $_
				Write-Error $_
			}
		}
	}
	# The end block is run after all inputs have been processed. Here it checks if there's any Error in the error list 
	# and if it's count is not equal to zero, writes an error message and stops the error action.
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}