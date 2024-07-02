function Invoke-DeviceADCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		$buildData
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("")) {
			throw "Not implemented ##TODO"
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}