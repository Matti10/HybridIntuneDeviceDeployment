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

		[Parameter()]
		$GUID = "",

		[Parameter(Mandatory)]
		[string]$OU = "",

		[Parameter(Mandatory)]
		[string[]]$groups,

		[Parameter()]
		[string]$freshLocation = "",

		[Parameter()]
		[string]$buildState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.initialState.message,

		[Parameter()]
		[string]$IntuneID = ""
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($AssetID)) {
			try {
				if ("" -eq $GUID) {
					$GUID = "$($serialNumber)-$((Get-Date).ToFileTimeUtc())"
				}
				
				return [PSCustomObject]@{
					AssetID      = $AssetID
					Hostname     = $hostname
					serialNumber = $serialNumber
					type         = $type
					build        = $build
					OU           = $OU
					groups       = $groups
					ticketID     = $ticketID
					buildState   = $buildState
					GUID         = $GUID
					freshAsset   = $freshAsset
					IntuneID     = $IntuneID
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