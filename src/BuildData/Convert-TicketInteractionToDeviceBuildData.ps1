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
				$raw = ConvertFrom-HTMLTable -html $text
				 throw "make this a build data obj"
				return 
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