function Show-DeviceUserMessage {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]
		$message,

		[Parameter(Mandatory)]
		[string]
		$title,

		[Parameter(Mandatory)]
		[int]
		$messageBoxConfigCode = $DeviceDeploymentDefaultConfig.DeviceUserInteraction.messageBoxConfigurations.Exclamation,

		[Parameter()]
		[int]
		$timeout = 0, # '0' keeps the popup open indefinitly 

		[Parameter()]
		[switch]
		$wait,

		[Parameter()]
		[string]
		$placeholder = $DeviceDeploymentDefaultConfig.DeviceUserInteraction.placeholderValue,

		[Parameter()]
		[string]
		$placeholderValue = $null
	)

	begin {
		$errorList = @()
	}
	process {
		try {

			if ($null -ne $placeholderValue) {
				$message = $message -replace $placeholder,$placeholderValue
			}

			if ($wait) {
				$wshell = New-Object -ComObject Wscript.Shell
				$result = $wshell.Popup($message, $timeout, $title, $messageBoxConfigCode)
			} else {
				Start-Job -Name $title -ScriptBlock {
					param($message, $timeout, $title, $messageBoxConfigCode)
					$wshell = New-Object -ComObject Wscript.Shell
					$result = $wshell.Popup($message, $timeout, $title, $messageBoxConfigCode)
				} -ArgumentList $message, $timeout, $title, $messageBoxConfigCode | Out-Null
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