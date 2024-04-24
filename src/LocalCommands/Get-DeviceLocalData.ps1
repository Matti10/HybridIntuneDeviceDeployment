function Get-DeviceLocalData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (

	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($identity)) {
			try {
				return @{
					hostname = HOSTNAME.EXE
					serialNumber = (Get-WmiObject win32_bios).SerialNumber
				}
			}
			catch {
				$errorList += $_
				Write-Error $_
			}
		} else {
			return @{
				hostname = "SomeTestHostName"
				serialNumber = "SomeTestSerial"
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}