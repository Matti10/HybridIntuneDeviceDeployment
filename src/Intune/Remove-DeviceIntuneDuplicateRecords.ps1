function Remove-DeviceIntuneDuplicateRecords {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo
	)

	begin {
		Connect-TriCareMgGraph
	}
	process {
		try {
			$duplicates = Get-MgDeviceManagementManagedDevice -Filter "serialNumber eq '$($buildInfo.serialNumber)'"
			foreach ($device in $duplicates) {
				if ($device.Id -ne $buildInfo.intuneID) {
					Write-Verbose "Removing $($device.ID)"
					Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -whatif:$WhatIfPreference -verbose:$VerbosePreference -ErrorAction stop
				}
			}
		} catch {
			New-BuildProcessError -errorObj $_ -message "Intune duplicate Cleanup has failed. Please search intune for any duplicate object with this devices serial number and manually delete any old objects." -functionName "Remove-DeviceIntuneDuplicateRecords" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
		}
	}
	end {
	}	
}