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

		[Parameter(Mandatory)]
		$logPath,

		[Parameter()]
		[string]$content = $DeviceDeploymentDefaultConfig.TicketInteraction.messageTemplate,

		[Parameter()]
		$errorState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.failedState,

		[Parameter()]
		[string]$dateFormat = $DeviceDeploymentDefaultConfig.Generic.DefaultDateFormat,

		[Parameter(Mandatory)]
		[string]$API_Key
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$BuildInfo.buildState = $errorState.message

			#format error message in a consumable manner
			$content = "An Error has occoured during the build process"

			if ($null -ne $errorObject) {
				$content += ", More details can be found below<br><b>Error Location: $($stack[1].Command)</b> <br><b>Error Message:</b> $($errorObject.exception.ErrorRecord)"
			}
			else {
				$content += " when running the $($stack[1].Command) function. More details can be found in the log file, located @ $log path<br>(remember, to access file explorer in OOBE, press shift+F10, then type 'explorer' into the cmd window)"
			}

			if ($null -ne $additionalInfo) {
				$content += "<br><b>Additional Infomation: </b>$additionalInfo"
			}

			#format the content
			$content = "<table><tr><th style=`"background-color:$($errorState.color)`">Error Information</th></tr><tr><td>$content</td></tr></table>"

			Write-DeviceBuildTicket -API_Key $API_Key -Message $content -whatif:$WhatIfPreference -buildInfo $BuildInfo
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