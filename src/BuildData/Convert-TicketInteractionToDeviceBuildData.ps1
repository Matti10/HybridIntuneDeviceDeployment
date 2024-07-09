function Convert-TicketInteractionToDeviceBuildData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
	
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]
		$text
		
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("")) {
			try {
				$raw = (ConvertFrom-HTMLTable -html $text)

				#parse groups
				$groups = $raw.groups.split(",") | ForEach-Object {$_.Trim(" ")} | Where-Object {$_ -ne ""}

				return (New-BuildInfoObj -AssetID $raw.AssetID -hostname $raw.hostname -serialNumber $raw.serialNumber -type $raw.type -build $raw.build -ticketID $raw.ticketID -freshAsset $raw.freshAsset -OU $raw.OU -groups $groups -buildState $raw.buildState -guid $raw.guid)
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