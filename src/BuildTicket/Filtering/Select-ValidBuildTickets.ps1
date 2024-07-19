function Select-ValidBuildTickets {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline)]
		$tickets,

		[Parameter()]
		[string[]]
		$buildTicketTitlePatterns = $DeviceDeploymentDefaultConfig.TicketInteraction.buildticketTitlePatterns
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("")) {
			try {

				if ($null -ne $tickets) {
					foreach ($pattern in $buildTicketTitlePatterns) {
						if ($tickets.subject -like $pattern) {
							return $tickets
						}
					}
				}
			} catch {
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
