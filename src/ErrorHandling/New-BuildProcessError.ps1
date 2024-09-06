
<# Documentation
# FUNCTION NAME: New-BuildProcessError

.SYNOPSIS
This function generates and handles errors during a build process.

.DESCRIPTION
The `New-BuildProcessError` function creates and handles errors found during the build process. It receives various parameters such as the error message, function name, and build information. Once invoked, it sends an email detailing the error if the debug mode is enabled, writes an error log, and creates a fresh error ticket.

.PARAMETER  errorObj
(Mandatory) This parameter is used to pass the error object.

.PARAMETER  message
(Mandatory) This is where the error message is being passed as a string.

.PARAMETER  buildInfo
This parameter contains additional information about the build process. Although not mandatory, the value is set as an empty string by default.

.PARAMETER  functionName
(Mandatory) The name of the function where the error(s) occurred.

.PARAMETER  popup
This switch parameter specifies whether a popup should be shown. It is optional. 
.PARAMETER  debugMode
This switch parameter decides if the function is running in debug mode. If this is provided, an email with  details of the error will be sent to a specified email address.

.NOTES
The function starts by initializing an empty array. Then, it evaluates whether it should continue processing based on the `$PSCmdlet.ShouldProcess` method. Within a `try` block, a message is composed containing both the message provided and the error object's details.

In the scope of the debug mode, an email is sent to the designated recipient with relevant error details. A nested `try` block attempts to execute the `Write-DeviceBuildError` function, provided that a build information object exists. If this process fails, a new error ticket will be logged using the `New-FreshErrorTicket` function.

Each encountered error is added to the `$errorList` array and displayed in the console. The error originating from the error object is displayed as well. Finally, if there are any errors recorded in `$errorList`, a summarizing error message is displayed and the function kills the process.

.EXAMPLE

New-BuildProcessError -errorObj $error -message "An error has occured in the build process" -functionName "TestFunction"

This will trigger the error handling process, with a custom error message and function name. #>
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}