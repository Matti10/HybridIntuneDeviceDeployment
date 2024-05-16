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
		if ($PSCmdlet.ShouldProcess($identity)) {
			try {
				$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
				
				$freshProduct = Find-FreshProductClosestMatch -model $systemInfo.model -API_Key $API_Key

				$type = Get-FreshAssetTypes -API_Key $API_Key
				| Where-Object {$_.ID -eq $freshProduct.asset_type_id}

				
				return @{
					hostname = $systemInfo.Name
					serialNumber = (Get-WmiObject win32_bios).SerialNumber
					model = $systemInfo.Model
					type = $type
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