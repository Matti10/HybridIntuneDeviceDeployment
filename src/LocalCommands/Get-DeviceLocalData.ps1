function Get-DeviceLocalData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (

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

			$freshProduct = Find-FreshProductClosestMatch -model $model

			$type = Get-FreshAssetTypes | Where-Object {$_.ID -eq $freshProduct.asset_type_id}

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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}