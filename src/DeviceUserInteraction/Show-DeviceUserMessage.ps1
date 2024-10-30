
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
# SIG # Begin signature block
# MIIPXQYJKoZIhvcNAQcCoIIPTjCCD0oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDRbAE2uZBhmij2
# FGWuPIplXRjrsc6jPfYgirnAhyY+LKCCDJ0wggXxMIIE2aADAgECAhM2AAAABHxF
# 1HD5VIC5AAAAAAAEMA0GCSqGSIb3DQEBCwUAMBoxGDAWBgNVBAMTD1RyaUNhcmUg
# Um9vdCBDQTAeFw0yMDA5MDgwMzM4NDNaFw0zMDA5MDgwMzQ4NDNaME0xEzARBgoJ
# kiaJk/IsZAEZFgNpbnQxGTAXBgoJkiaJk/IsZAEZFgl0cmljYXJlYWQxGzAZBgNV
# BAMTElRyaUNhcmUgSXNzdWluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAMon7aRIEIWMmB7TY0emDAy0qT+QBAbi0ycVW/C9SRoLl5eNUa2Xweh6
# n7iIrHt7va9WwFV51gxDQfp8HUSek6n9+pS74VsNqeAakfha18WS2cKd+BgCuQT7
# 2B3Ve2iS+oGhpdXz8Sws+3aV6jt4Rf1c0Spq9N4KE5DADxkDK1p0JRDM/Kb9jWjB
# Q0zcFBrd7ggzCehu/VdIP5bfFz1Loyzlu6jbqVUNGib90U/T8Lpq1Q3QOv3wz7HN
# YtALsMf/PpeGLt7iVmnbxCn1nQwdOollmoB7yto1CqS+Mu/Rh8a0YIpJJOcbQJVW
# Rrs3Tzm3hSSWen8ZFE0qrl6kEMU0ocUCAwEAAaOCAvswggL3MBAGCSsGAQQBgjcV
# AQQDAgEBMCMGCSsGAQQBgjcVAgQWBBQaNbVVMWI/Z3runFlYbTtXTBijDDAdBgNV
# HQ4EFgQUiHluakoRshLt+cEO73gjCJchv8IwGQYJKwYBBAGCNxQCBAweCgBTAHUA
# YgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU
# wK6BYlHmTNa+I4IjwrVfXMVzQNEwggEdBgNVHR8EggEUMIIBEDCCAQygggEIoIIB
# BIaBw2xkYXA6Ly8vQ049VHJpQ2FyZSUyMFJvb3QlMjBDQSxDTj1UQy1BRS1QLUNB
# Ui0wMSxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vydmlj
# ZXMsQ049Q29uZmlndXJhdGlvbixEQz10cmljYXJlYWQsREM9aW50P2NlcnRpZmlj
# YXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRp
# b25Qb2ludIY8aHR0cDovL2NydC50cmljYXJlLmNvbS5hdS9DZXJ0RW5yb2xsL1Ry
# aUNhcmUlMjBSb290JTIwQ0EuY3JsMIIBIgYIKwYBBQUHAQEEggEUMIIBEDCBtAYI
# KwYBBQUHMAKGgadsZGFwOi8vL0NOPVRyaUNhcmUlMjBSb290JTIwQ0EsQ049QUlB
# LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
# Z3VyYXRpb24sREM9dHJpY2FyZWFkLERDPWludD9jQUNlcnRpZmljYXRlP2Jhc2U/
# b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTBXBggrBgEFBQcwAoZL
# aHR0cDovL2NydC50cmljYXJlLmNvbS5hdS9DZXJ0RW5yb2xsL1RDLUFFLVAtQ0FS
# LTAxX1RyaUNhcmUlMjBSb290JTIwQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQCV
# CMS3uwic/p24nizjQjMr7I87WuDT8u9UFfAFBAjCiyyr9SKfwlYC/LGaGjCikElP
# Ad2oBKG/JoG2zZsH1hIWSFkh2vXMRAIkQ7dircW9zl0r/hFe8YRYla5znRRxN3rc
# TN7aFG09aC+p6oSambOR0f7qgL4BrzORLVKqbyDRZc/ADagYwtdPOWVtoR2XBPv+
# RaYNXWlR5sXicx3p7qtjkj2nu+gmQtyErB4ZN5kQbBNC6VN19WTlLhHIOr9BlHPh
# oGBWDRk+6DiOXGcLlRQ1ZF5jSRpjdkeBKgP86DodzLYDYic+++N67W3BHEGm7Xlr
# XnTvOC4HoeSy7+jlIlYrMIIGpDCCBYygAwIBAgITMwAAAR7DquNi3NxjXAABAAAB
# HjANBgkqhkiG9w0BAQsFADBNMRMwEQYKCZImiZPyLGQBGRYDaW50MRkwFwYKCZIm
# iZPyLGQBGRYJdHJpY2FyZWFkMRswGQYDVQQDExJUcmlDYXJlIElzc3VpbmcgQ0Ew
# HhcNMjQwNzI1MDUyNTI5WhcNMjUwNzI1MDUyNTI5WjAWMRQwEgYDVQQDEwtNYXR0
# IFdpbnNlbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK636Hyxorhg
# 7iDwfttShVtUDdUz1aSUAemOt6uuu2ZGIW1E2jayTQ/r/r6ogXDaYhEWI8XM84mo
# XKTGIYdgskQ41Wg3K1Lc1pkLBzpXu3CTBU+LHz9MvhcKK8YGGleghvzJXkpMQm96
# faDkQ9wftErhzUkD+ItemnhFpvmsVkNaFHNPIyQzOeZPlw3crWpDeDreQHAHDdTT
# IfwY9PiLJAPiJuN6/GRo7wRygFVY2ug5AVU1FWZ9oYSMNevt1Of7C/NfS0z3mTcN
# x7HKTwGbbb4Kd0J9jOg/AP4s8wl18Mu1vX+8Fx3CnFbtcyExST1XzQQp31K7PWeu
# U7fli4Pl6JUCAwEAAaOCA7IwggOuMD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcV
# CISevyGEk+0bh+2ZF4bkljiEyOMcMIKV3CKBmu0FAgFkAgECMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsG
# AQUFBwMDMB0GA1UdDgQWBBTHAkTv1pRdRoHRJ+cV9DGIpYIPLjAfBgNVHSMEGDAW
# gBSIeW5qShGyEu35wQ7veCMIlyG/wjCCASMGA1UdHwSCARowggEWMIIBEqCCAQ6g
# ggEKhj9odHRwOi8vY3J0LnRyaWNhcmUuY29tLmF1L0NlcnRFbnJvbGwvVHJpQ2Fy
# ZSUyMElzc3VpbmclMjBDQS5jcmyGgcZsZGFwOi8vL0NOPVRyaUNhcmUlMjBJc3N1
# aW5nJTIwQ0EsQ049VEMtQUUtUC1DQUktMDEsQ049Q0RQLENOPVB1YmxpYyUyMEtl
# eSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9dHJp
# Y2FyZWFkLERDPWludD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwggE5BggrBgEFBQcBAQSCASsw
# ggEnMGsGCCsGAQUFBzAChl9odHRwOi8vY3J0LnRyaWNhcmUuY29tLmF1L0NlcnRF
# bnJvbGwvVEMtQUUtUC1DQUktMDEudHJpY2FyZWFkLmludF9UcmlDYXJlJTIwSXNz
# dWluZyUyMENBKDEpLmNydDCBtwYIKwYBBQUHMAKGgapsZGFwOi8vL0NOPVRyaUNh
# cmUlMjBJc3N1aW5nJTIwQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZp
# Y2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9dHJpY2FyZWFkLERD
# PWludD9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlv
# bkF1dGhvcml0eTA1BgNVHREELjAsoCoGCisGAQQBgjcUAgOgHAwaTWF0dC5XaW5z
# ZW5AdHJpY2FyZS5jb20uYXUwUAYJKwYBBAGCNxkCBEMwQaA/BgorBgEEAYI3GQIB
# oDEEL1MtMS01LTIxLTMxNDIzNTc0MjUtMzQzNDUxMDI3Ni0zMTczMTgzMDk3LTE0
# NTMyMA0GCSqGSIb3DQEBCwUAA4IBAQA4RvSw6PxgNnAIB/uMpj1CAQU4zXDCZV27
# lHBkAeKt8e9FWmOn5S4MEIF013hxYsFnirU5wzGcMpfsw4V9BG7sFYc1BZnvKV3u
# n3X8+dRWgxkeGRY7MtQNnwFbSmTgFBeaDoSRTwGMlVK029nd/osmN1T+4KOcyHUX
# PHKvZGyiPHjZl4w9rMD7KEoIoyZl0yop9zsnIXh52gH+QMXs2hb+SaQWC7UP+XCZ
# TlT9NTUGkFSz+mhlUew6NItouWkpqy0cnzIBI24J9Ul2zw3wTTMdL4x/Icdsdc1K
# NDoOUMsClsgxndEiIfYlH8gLLNWI6TFtspBcu3H8WG2TCWaBtE+7MYICFjCCAhIC
# AQEwZDBNMRMwEQYKCZImiZPyLGQBGRYDaW50MRkwFwYKCZImiZPyLGQBGRYJdHJp
# Y2FyZWFkMRswGQYDVQQDExJUcmlDYXJlIElzc3VpbmcgQ0ECEzMAAAEew6rjYtzc
# Y1wAAQAAAR4wDQYJYIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgCDbHOUyaJmoStE4qMOvt4oTb
# 3uGKl3Ln1v2SZetS7eIwDQYJKoZIhvcNAQEBBQAEggEArOQi+XOmaZ5Ws+GRB2UX
# d8AIMGxMqRNnTspArUwu13UZ2I3IQK8ULUUejME07wswIMZNBgthinnjTJi35ZEB
# vT6HdOPl6tvHNn1ZuTfeVQCnJPyQXfBtDTSoOdZzhXiqYsB9e2VA7yhtuxkriNBC
# V7b44GMAQPtAgeXe+lcPMYLanfmgOqU+RC70zMceiM/iLyZltWtJH9qDgiUKnUXd
# U8cPIs8knfwlNgfUBBfWsUYOOCe7pWGcEkaWVxVkVSpWO3fmnq6IMt8xHd20i42D
# NlSXrnQdRTV7oL/A1Bk88Aa2szZaaVhMp4rOEha6io3KE+i7jMd6GHW4CCTc8I+q
# cQ==
# SIG # End signature block
