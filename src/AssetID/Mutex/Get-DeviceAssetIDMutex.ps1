
<#
.DESCRIPTION

The Get-DeviceAssetIDMutex function is a custom Cmdlet written in PowerShell that fetches the details of a specific object in the device deployment configuration. 

It particularly checks if a record relating to a custom object has been accessed or not. Based on these checks, it returns the status of the record accessed and who set it.

Specifically, it uses the Get-FreshCustomObjectRecords function (another custom function not defined in this script) to fetch the object detail from a system, aggregates all encountered errors, and writes them to the output before stopping the execution.

_$CurrentlyAccessed_ is a boolean variable that is determined by checking if the _CurrentlyAccessed_ property of the retrieved object matches the _AccessedValue_ or _NotAccessedValue_

.PARAMETERS

.PARAMETER objectID
[string], defaults to $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectID, represents the identification for the object to be fetched.
.PARAMETER recordID
[string], defaults to $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectRecordID, id of the record in fresh
.PARAMETER accessedValue
[string], defaults to $DeviceDeploymentDefaultConfig.AssetID.AccessedValue, the value that represents "accessed"
.PARAMETER notAccessedValue
[string], defaults to $DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue, the value that represents "not accessed"

.EXAMPLE

EXAMPLE 1:  
`Get-DeviceAssetIDMutex -objectID "object123" -recordID "record456" -accessedValue "accessed" -notAccessedValue "notAccessed"`

This command fetches the object with the ID of "object123", checks the record with the display ID "record456" if it has been accessed or not, and returns a custom object.

.NOTES

The $DeviceDeploymentDefaultConfig variable mentioned in the argument defaults appears to be a global or script-wide variable because there's no indication of where it's defined or what it contains within this function. The values could objectively be any kind of configuration details used in the device deployment process.

#>
function Get-DeviceAssetIDMutex {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (


		[Parameter()]
		[string]$objectID = $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectID,

		[Parameter()]
		[string]$recordID = $DeviceDeploymentDefaultConfig.AssetID.MutexFreshObjectRecordID,

		[Parameter()]
		[string]$accessedValue = $DeviceDeploymentDefaultConfig.AssetID.AccessedValue,

		[Parameter()]
		[string]$notAccessedValue = $DeviceDeploymentDefaultConfig.AssetID.NotAccessedValue
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($recordID)) {
			try {
				$value = (Get-FreshCustomObjectRecords -objectID $objectID) | Where-Object {$_.bo_display_id -eq $recordID} #there is only one record, get position one just to be sure

				if ($value.CurrentlyAccessed -eq $notAccessedValue) {
					$currentlyAccessed = $false
				} elseif ($value.CurrentlyAccessed -eq $accessedValue) {
					$currentlyAccessed = $true
				} else {
					return Repair-DeviceAssetIDMutex
				}

				return [PSCustomObject]@{
					currentlyaccessed = $CurrentlyAccessed
					setby = $value.SetBy
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