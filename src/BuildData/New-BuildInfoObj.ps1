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

		[Parameter()]
		[string]$OU = "",

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

				if ($OU -eq "") {
					if ($freshLocation -ne "") {
						$OU = Get-DeviceBuildOU -build $build -facility $freshLocation
					}
					else {
						Write-Error "OU & freshLocation are both empty, please provide data for one of these paramaters" -ErrorAction stop
					}
				}

				if ($serialNumber -eq "") {
					#TODO - Get-FreshAssetSerialNUmber?
				}

				return [PSCustomObject]@{
					AssetID      = $AssetID
					serialNumber = $serialNumber
					type         = $type
					build        = $build
					OU           = $OU
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