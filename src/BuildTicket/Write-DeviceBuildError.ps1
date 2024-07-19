function Write-DeviceBuildError {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$BuildInfo,

		[Parameter()]
		$errorObject = $null,

		[Parameter()]
		$stack = (Get-PSCallStack),

		[Parameter()]
		$additionalInfo = $null,

		[Parameter()]
		$logPath = $DeviceDeploymentDefaultConfig.Logging.buildPCLogPath,

		[Parameter()]
		[string]$content = $DeviceDeploymentDefaultConfig.TicketInteraction.messageTemplate,

		[Parameter()]
		$errorState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.failedState,

		[Parameter()]
		[string]$message,

		[Parameter()]
		[string]$dateFormat = $DeviceDeploymentDefaultConfig.Generic.DefaultDateFormat
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$BuildInfo.buildState = $errorState.message

			#format error message in a consumable manner
			$content = "An Error has occoured during the build process"

			# low effort attempt to get the error message (its stored in different places....)
			try {
				$errorMsg = $errorObject.exception.Message
			} catch {
				try {
					$errorMsg = $errorObject.exception.ErrorRecord
				}
				catch {
					$errorMsg = "Unknown"
				}
			}

			# put message together
			if ($null -ne $errorObject) {
				$content += ":<br><b>Solution & Details:</b> $message<br><b>Error Location/Function:</b> $($stack[1].Command)<br><b>Error Message:</b> $($errorMsg)<br>"
			}
			else {
				$content += " when running the $($stack[1].Command) function. More details can be found in the log file, located @ $logPath path<br>(remember, to access file explorer in OOBE, press shift+F10, then type 'explorer' into the cmd window)"
			}

			if ($null -ne $additionalInfo) {
				$content += "<br><b>Additional Infomation: </b>$additionalInfo"
			}

			#format the content
			$content = "<table><tr><th style=`"background-color:$($errorState.color)`">Error Information</th></tr><tr><td>$content</td></tr></table>"

			Write-DeviceBuildTicket -Message $content -whatif:$WhatIfPreference -buildInfo $BuildInfo

			#vomit out the stack trace for the nerds
			Write-Host "StackTrace:"
			foreach ($call in $stack) {
				Write-Host "$($call)"
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