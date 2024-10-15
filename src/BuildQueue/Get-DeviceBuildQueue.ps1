
function Get-DeviceBuildQueue {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		$customObjectID = $DeviceDeploymentDefaultConfig.BuildQueue.CustomObjectID,
		
		[Parameter()]
		$listDisplayDelimiter = $DeviceDeploymentDefaultConfig.TicketInteraction.listDisplayDelimiter
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			return Get-FreshCustomObjectRecords -objectID $customObjectID | Convert-BuildQueueToBuildData
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