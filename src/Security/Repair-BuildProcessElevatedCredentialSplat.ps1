
# Documentation
<#

#>
function Repair-BuildProcessElevatedCredentialSplat {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
		[int]$CredentialMaxRetry = $DeviceDeploymentDefaultConfig.Security.CredentialMaxRetry,

		[Parameter(Mandatory)]
		[int]$CredentialRetryCount
	)

	# Begin block executes at the start of the function
	begin {
		# Initialize $errorList as an empty array to store any potential errors
		$errorList = @()
	}
	# Process block executes for each pipeline object passed to the function
	process {
		try {
			if ($CredentialRetryCount -ge $CredentialMaxRetry) {
				#if we've retryed to many times, give up and error
				Write-Error -message "Elevated Credentials are invalid. Credentials from KV have been retived $credentialRetryCount times and none have been valid" -ErrorAction Stop
			}

			Register-BuildProcessElevatedCredentailsScriptWide -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference #get creds from KV and re-register them module wide

			return Build-CredentialSplat
		}
		# Catch any errors and add them to $errorList and display an error message
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	# End block executes after the process block (after all pipeline objects have been processed)
	end {
		if ($errorList.count -ne 0) {
			# If there are any errors, write them all and stop execution
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}
# SIG # Begin signature block
# MIIPXQYJKoZIhvcNAQcCoIIPTjCCD0oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD8jmW11CSB/PnT
# zCJmcZvoEGTUg1yWE2rIbTW0WO1N3aCCDJ0wggXxMIIE2aADAgECAhM2AAAABHxF
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
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg6SBVI6hnnIgj7sLgQPrkcZ9X
# GPRpHlubjQH3YcS5o38wDQYJKoZIhvcNAQEBBQAEggEAGsYiJD7fgRsI6wPCvp3Y
# qI6Cg7BQoUTfYmpG1rJ2a+HiGftAjXGjLLO+kJcCRSc/Abyi1xsoeeCkGUVxqbOj
# HQBcnMrzQIljHYkJx8Wok+Eu4cQdCJL+lC6QPdJkmqcGtKy4lsr+6NQgCOwrwxzC
# 2ScZusZ8Xg3MCvONBzo13CIMN6ynivQ93pYdOM8PBjgGVlhw8h2VuaN9e+mTmPPD
# X3dIYE7XUwC+TFbtGwUB2uMpJAv9lGPjfV8U/uT8SeKuChbo1prlhDoQz24rFkga
# LfY+hnSJ8wUHWYy5/YVoGe+e+AGJrZFzpolRZA3/2poWA+x8FLFW+Wq982UCEEYA
# eQ==
# SIG # End signature block
