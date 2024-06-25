function Get-DeviceLocalData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		$API_Key
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			if ($PSCmdlet.ShouldProcess("The current device")) {
				$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
				$model = $systemInfo.model
				$hostname = $systemInfo.Name
				$serial =  (Get-CimInstance -ClassName win32_bios).SerialNumber
			} else {
				$model = "Surface"
				$hostname = "SomeTestHostName"
				$serial =  "SomeTestSerial"
			}

			$freshProduct = Find-FreshProductClosestMatch -model $model -API_Key $API_Key

			$type = Get-FreshAssetTypes -API_Key $API_Key | Where-Object {$_.ID -eq $freshProduct.asset_type_id}

			return @{
				hostname = $hostname
				serialNumber = $serial
				model = $freshProduct.Name
				type = $type.Name
			}

		
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}