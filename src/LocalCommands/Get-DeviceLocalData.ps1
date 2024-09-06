
<# Documentation
Function Name: Get-DeviceLocalData

Summary: 
This function retrieves the local system information such as host name, model name, and serial number. If there are errors during the process, they are stored in a list and output in the end block.


.Synopsis
Retrieves local system information including host name, model name, and serial number.

.Description
The function Get-DeviceLocalData retrieves information about the local device, including the system's host name, model name and serial number. This information is obtained either by a built-in Powershell cmdlet called Get-CimInstance, or from hard coded values, depending on system permissions. The function also finds the nearest match to the model name, and fetches its corresponding asset type. At the end of the process, it returns a hash table containing the aforementioned system information. If there are any exceptions thrown during execution, they are added to the `$errorList` and output accordingly.



.OUTPUTS
The return value is a hash table containing the following information:

- Hostname
- SerialNumber
- Model name
- Asset type


.Example
    PS C:\> Get-DeviceLocalData

    This will output a hash table with the host name, model name, serial number, and type of the device.

.NOTES
This function uses the built-in cmdlet `Get-CimInstance` to retrieve system information. However, if the cmdlet doesn't have the necessary permissions, it will return hard coded values for the host name, model, and serial number. The function handles this scenario in the `catch` block by adding any exception to the `$errorList`, which is later output for debugging purposes.

The function also uses `Find-FreshProductClosestMatch` to find the closest match for the model, and `Get-FreshAssetTypes` to fetch asset types, presumably from an external source or service. These helper functions are assumed to be defined elsewhere in the overall script or module.
   #>
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