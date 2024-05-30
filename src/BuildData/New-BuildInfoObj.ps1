function New-BuildInfoObj {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$AssetID,

		[Parameter()]
		[string]$serialNumber = "",

		[Parameter(Mandatory)]
		[string]$type,

		[Parameter(Mandatory)]
		[string]$build,

		[Parameter(Mandatory)]
		[string]$ticketID,

		[Parameter(Mandatory)]
		$freshAsset,

		[Parameter(Mandatory)]
		[string]$OU = "",

		[Parameter(Mandatory)]
		[string[]]$groups,

		[Parameter()]
		[string]$freshLocation = "",

		[Parameter()]
		[string]$buildState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.initalState.message
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($AssetID)) {
			try {
				return [PSCustomObject]@{
					AssetID      = $AssetID
					serialNumber = $serialNumber
					type         = $type
					build        = $build
					OU           = $OU
					groups       = $groups
					ticketID     = $ticketID
					buildState   = $buildState
					freshAsset   = $freshAsset
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}