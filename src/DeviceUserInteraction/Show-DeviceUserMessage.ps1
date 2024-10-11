
<# Documentation
## Function Name: Show-DeviceUserMessage

.Synopsis

This PowerShell function shows a user defined message box to the user device using Windows Script Host (WSH).

.Description

The Show-DeviceUserMessage function creates a new dialog window or message box that can be utilized to inform an end-user about a specific operation or to get input from the end-user.

 

.Parameter Message
This mandatory parameter accepts a string value representing the message to be displayed in the message box.
.Parameter Title
This mandatory parameter accepts a string value that defines the title of the message box.
.Parameter MessageBoxConfigCode
This parameter allows the user to specify a specific message box type. The type is an integer value and is mandatory. By default, it uses the 'Exclamation' configuration from the `DeviceDeploymentDefaultConfig.DeviceUserInteraction.messageBoxConfigurations` object.
.Parameter Timeout
This optional parameter sets the duration for the message box to be displayed to a user. If set to '0', the popup will stay open indefinitely.
.Parameter Wait
This optional switch parameter forces the command to wait for the message box to be closed by the user before the script continues.
.Parameter Placeholder
This parameter is used only if a placeholder is defined in the `DeviceDeploymentDefaultConfig.DeviceUserInteraction.placeholderValue` and needs to be replaced in the message. 
.Parameter PlaceholderValue
Specifies the new value that will replace the placeholder in the message. The substitution is performed only if this value is not `$null`.

.Example

Example 1:

Show-DeviceUserMessage -Message "This is an error message" -Title "Error" -MessageBoxConfigCode 0 -Wait

Example 2:

$message = "Please close all open programs and save your work. Your computer will automatically restart in 5 minutes"
Show-DeviceUserMessage -Message $message -Title "System Notification" -Timeout 300

.Notes

This function uses the COM interface of the Windows Script Host to show the message boxes, hence it can be blocked by settings in the Internet Explorer or by user access control.

Related links:

- [Windows Script Host](https://docs.microsoft.com/en-us/previous-versions//9bbdkx3k(v=vs.85))
- [MsgBox function (VBScript)](https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/windows-scripting/x83z1d9f%28v%3dvs.84%29)
#>
function Show-DeviceUserMessage {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]
		$message,

		[Parameter(Mandatory)]
		[string]
		$title,

		[Parameter()]
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

				return $result
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
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}