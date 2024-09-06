
<#
.SYNOPSIS
This function sets a new value to the device asset ID mutex.

.DESCRIPTION
This function sets a new value to the device asset ID mutex based on the condition whether the mutex has been accessed or not. If no valid state for the field CurrentlyAccessed is found, the function `Repair-DeviceAssetIDMutex` is called for repair. 

.PARAMETER mutex
The key object which can be accessed by only one thread at a time. Mandatory parameter.

.PARAMETER objectID
Specifies the object ID used for setting the new value of the asset. 

.PARAMETER recordID
Specifies the record ID used for setting the new value of the asset.

.PARAMETER accessedValue
Value that will be set if the mutex has been accessed.

.PARAMETER notAccessedValue
Value that will be set if the mutex has not been accessed.

.EXAMPLE
Set-DeviceAssetIDMutex -mutex $testMutex -objectID 'testID' -recordID 'recordID' -accessedValue 'Yes' -notAccessedValue 'No'

.NOTES
This function requires the `Set-FreshCustomObject` function to commit the new value to the asset.
#>

function Set-DeviceAssetIDMutex {
	# CmdletBinding attribute is used to permit the use of the common parameters: -Verbose, -Debug, -ErrorAction, -ErrorVariable, -WarningAction, -WarningVariable, -OutBuffer, and -OutVariable.
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (

		# The mandatory parameter that represents the mutex object.
		[Parameter(Mandatory)]
		[Object]$mutex,

		# The Object ID used to set the new value for the asset ID.
		[Parameter()]
		[string]$objectID = $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectID,

		# The Record ID used to set the new value for the asset ID.
		[Parameter()]
		[string]$recordID = $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectRecordID,

		# The value to be set if the mutex has been accessed.
		[Parameter()]
		[string]$accessedValue = $DeviceDeploymentDefaultConfig.AssetID.AccessedValue,

		# The value to be set if the mutex has not been accessed.
		[Parameter()]
		[string]$notAccessedValue = $DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue
	)

	begin {
		# Initialize an array to hold any potential errors
		$errorList = @()
	}
	process {
		# Check if the action should be performed (a 'what if' execution)
		if ($PSCmdlet.ShouldProcess($recordID)) {
			try {
				# If the mutex has been accessed, set the new value to the accessedValue
				if ($mutex.CurrentlyAccessed -eq $true) {
					$mutex.CurrentlyAccessed = $accessedValue
				} 
				# If the mutex has not been accessed, set the new value to the notAccessedValue
				elseif ($mutex.CurrentlyAccessed -eq $false) {
					$mutex.CurrentlyAccessed = $notAccessedValue
				} 
				# If no valid state for CurrentlyAccessed is found, repair it
				else {
					return Repair-DeviceAssetIDMutex
				}

				# Set the new value to the asset ID and return its data
				return (Set-FreshCustomObject -objectID $objectID -recordID $recordID -record $mutex).custom_object.data
			}
			catch {
				# Catch any errors, add them to the error list, and write them to the error stream
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		# If there were any errors during the process, throw an error with all the error messages
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}