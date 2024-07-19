function New-BuildProcessError {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		$errorObj,

		[Parameter(Mandatory)]
		[string]$message,

		[Parameter()]
		$buildInfo = "",

		[Parameter(Mandatory)]
		[string]$functionName,

		[Parameter()]
		[switch]$popup,

		[Parameter()]
		[switch]$debugMode

	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			try {
				$userFriendlyMessage = "$message`nError Detail:`n$($errorObj)"

				if ($debugMode) {
					Send-eMailMessage -FromEmail "matt.winsen@tricare.com.au" -ToEmail "matt.winsen@tricare.com.au" -Subject "Build Process Error | $functionName" -Body "$($buildInfo | ConvertTo-JSON)`n$errorObj`n" -Verbose:$VerbosePreference
				}

				try {
					if ("" -ne $buildInfo) {
						Write-DeviceBuildError -buildInfo $buildInfo -message $message -errorObject $errorObj
					} else {
						Write-Error "No Build Info Obj" -ErrorAction "Stop"
					}
				}
				catch {
					New-FreshErrorTicket -ErrorMsg $userFriendlyMessage -filename $functionName -clientName "$(hostname)" -logPath "C:\Intune_Setup\buildProcess\logs" -ErrorObjs $errorObj
				}

			}
			catch {
				$errorList += $_
				Write-Error $_
			}

			Write-Error $errorObj -ErrorAction:$ErrorActionPreference #write the error to console
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}