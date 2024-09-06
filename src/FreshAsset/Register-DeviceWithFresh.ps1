
# Documentation
<#
.SYNOPSIS
This function registers a device with Fresh Service and returns the Fresh Asset.

.DESCRIPTION
This function first fetches the device local data including its serial number, type and model.
It then acquires a mutex to protect names from concurrent access and gets the device AssetID.
The function checks whether a Fresh Asset already exists for the device and if its name matches the AssetID. 
If it exists but the name doesn't match, it sets the correct name.
If the asset doesn't exist, it creates a new one.
After a set amount of pause to enable asset creation, it then returns the Fresh Asset.

.PARAMETER localDeviceInfo
This parameter represents the local data info of the device.
By default, it collects the device local data.

.EXAMPLE
To run this command:
Register-DeviceWithFresh -localDeviceInfo (Get-DeviceLocalData)
#>

function Register-DeviceWithFresh {
	# Bind cmdlet to use ShouldProcess
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Parameter to capture the local device info, by default it uses Get-DeviceLocalData to fetch the info
		[Parameter()]
		$localDeviceInfo = (Get-DeviceLocalData)
	)
	
	begin {
		# Initialize an error list
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("The current device")) {
				
				# Acquire mutex to protect names from concurrent access 
				$mutex = Protect-DeviceAssetIDMutex -Verbose:$VerbosePreference
				
				# Get the device AssetID
				$AssetIDInfo = (Get-DeviceAssetID -serialNumber $localDeviceInfo.serialNumber -disaplyUserOutput)

				# Split variables 
				$freshAsset = $AssetIDInfo.freshAsset
				$AssetID = $AssetIDInfo.AssetID

				# Test if fresh asset exists
				if ($null -ne $freshAsset) {
					# Test if fresh assets name is correct 
					if ($freshAsset.Name -ne $AssetID) {
						# If the fresh asset name is incorrect, then set the correct fresh asset name
						Set-FreshAssetName -FreshAsset $freshAsset -name $AssetID
					}
				} else {
					# Create a new fresh asset if none existed before
					New-FreshAsset -name $AssetID -type $localDeviceInfo.type -model $localDeviceInfo.model -serial $localDeviceInfo.serialNumber

					# Wait breifly to allow asset to be created before checking it exists and returning
					Start-Sleep -Milliseconds 500
				}

				# Release the mutex
				$mutex = Unprotect-DeviceAssetIDMutex -mutex $mutex -Verbose:$VerbosePreference

				# Pause to give time for fresh server to create asset
				Start-Sleep -Seconds 10

				# Return the fresh asset
				return Get-FreshAsset -name $AssetID -ErrorAction Stop
		}
		}
		catch {
			# Handle any errors and unprotect the mutex
			Unprotect-DeviceAssetIDMutex -mutex $mutex

			# Capture error messages
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		# Check if there were any errors and output them
		if ($errorList.count -ne 0) {
			# Write all the errors and stop the execution
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}