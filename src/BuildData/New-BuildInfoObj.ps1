function New-BuildInfoObj {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$AssetID,

		[Parameter()]
		[string]$hostname = "$(hostname)",

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
		[string]$buildState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.initialState.message
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($AssetID)) {
			try {
				return [PSCustomObject]@{
					AssetID      = $AssetID
					Hostname     = $hostname
					serialNumber = $serialNumber
					type         = $type
					build        = $build
					OU           = $OU
					groups       = "$($groups | ForEach-Object {"$_,"})"
					ticketID     = $ticketID
					buildState   = $buildState
					GUID         = "$($serialNumber)-$((Get-Date).ToFileTimeUtc())"
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