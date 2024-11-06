
# Documentation
<#
.SYNOPSIS
This function will invoke Active Directory (AD) commands for a specified device. It adds the device to specified AD Groups and moves the device to a correct Organizational Unit (OU).

.DESCRIPTION
The Invoke-DeviceADCommands function first attempts to find an AD Computer object by its AssetID. If the object cannot be found by AssetID, it will then try to identify it by the Hostname. If both methods fail, an error message will be written.

Once the AD Computer object is identified, the function will add it to the specified AD Groups. If this process fails, an error message is triggered.

Finally, it will attempt to move the AD computer object to the specified OU. 

Any errors that occur during the process will be captured and used to create a build process error. Once all commands have been processed, the AD commands completion string will be added to the device's build state and updated in the build ticket.

.PARAMETER buildInfo
This mandatory parameter contains details about the build process of a device such as its AssetID, Hostname, OU and groups.

.PARAMETER ADCommandsCompletedString
The string to be used to denote that AD commands have been completed. Defaults to the message from the 'adCompletedState' of the 'BuildStates' in the 'DeviceDeploymentDefaultConfig' if not explicitly provided.

.EXAMPLE
Invoke-DeviceADCommands -buildInfo $buildInfo -ADCommandsCompletedString "AD Commands Completed Successfully."

This example would attempt to add the device as described in the input object $buildInfo to the specified AD groups and move to the assigned OU. Then it updates the build ticket to indicate that the AD commands for the device have been completed successfully.

.INPUTS
PSCustomObject from Pipeline
The object should have properties: AssetID, Hostname, OU, Groups

.OUTPUTS 
Outputs build information string.
The function will output to the console if it successfully adds to the device groups, moves it to the correct OU and then updates the build ticket to include a message that AD commands have been completed.
#>

function Invoke-DeviceADCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		$ADCommandsCompletedString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message,

		[Parameter()]
		[switch]$remoteMachine,

		[Parameter()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential = $Script:ADElevatedCredential, # This is null by default
		
		[Parameter()]
		[int]$CredentialRetryCount = 0
	)

	begin {
		$msg = ""
		$errorList = @()
		
		#manage credentials using splatting
		$credentialSplat = Build-CredentialSplat -Credential $Credential

		# helper function to change credentials mid execution while in debug mode
		function Invoke-DebugHelper {
			if ($DebugPreference -ne "SilentlyContinue") {
				return Repair-BuildProcessElevatedCredentialSplat -CredentialRetryCount 0
			}
		}
	}
	process {
		try {
			#------------------------------------------- Get AD Comp -------------------------------------------#
			$ADComp = $null #init AD Comp as null
			while ($null -eq $ADComp) {
				try {
					$ADComp = Get-ADComputer -Identity $buildInfo.AssetID @credentialSplat
				}
				catch [System.Security.Authentication.AuthenticationException], [Microsoft.ActiveDirectory.Management.ADServerDownException] {
					# catch credential failure and retry
					$credentialSplat = Repair-BuildProcessElevatedCredentialSplat -CredentialRetryCount $CredentialRetryCount -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference

					$CredentialRetryCount++ 
					
				}
				catch {
					# if comp cant be found using asset id, try with hostname (lest rename fails)
					try {
						if (-not $remoteMachine) {
							$ADComp = Get-ADComputer -Identity $buildInfo.hostname @credentialSplat
						}
						else {
							throw $_
						}
					}
					catch {
						# check that the error wasn't a credential failure on second Get-ADComputer
						if ($_.Exception.GetType().FullName -like "*Authentication*" -or $_.Exception.GetType().FullName -like "*ADServerDown*") {
							#do nothing, this will result in loop looping, auth error will then be handled by specific catch block above
						}
						else {
							Write-Error "Computer with AssetID/Hostname $($buildInfo.AssetID)/$($buildInfo.hostname) doesn't exist in AD" -ErrorAction stop
						}
					}
				}
			}
			
			#------------------------------------------ Add to Groups ------------------------------------------#
			$credentialSplat = Invoke-DebugHelper #re-register credentials if in debug mode
			$CredentialRetryCount = 0 #reset the retry counter
			$groupsSuccess = $false
			while (-not $groupsSuccess) {
				foreach ($group in $buildInfo.groups) {
					try {
						Add-ADGroupMember -Identity $group -Members $ADComp.SamAccountName -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference @credentialSplat
						Write-Verbose "Adding $($ADComp.SamAccountName) to $group"
						
					}
					catch [System.Security.Authentication.AuthenticationException], [Microsoft.ActiveDirectory.Management.ADServerDownException] {
						# catch credential failure and retry
						$credentialSplat = Repair-BuildProcessElevatedCredentialSplat -CredentialRetryCount $CredentialRetryCount -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference

						$CredentialRetryCount++ 

						Continue # restart group addition from the beginning of while loop
					}
				}
				$groupsSuccess = $true #if we reach this stage (i.e. haven't hit the continue in the catch block) we've succeeded!
			}
			
			#---------------------------------------- Move to Correct OU----------------------------------------#
			$credentialSplat = Invoke-DebugHelper #re-register credentials if in debug mode
			$CredentialRetryCount = 0 #reset the retry counter
			$moveSuccess = $false
			while (-not $moveSuccess) {
				if ($ADComp.DistinguishedName -notlike "*$($buildInfo.OU)*") {
					try {
						Move-ADObject -Identity $ADComp.DistinguishedName -TargetPath $buildInfo.OU -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference @credentialSplat
						Write-Verbose "Moving $($ADComp.SamAccountName) to $($buildInfo.OU)"
					}
					catch [System.Security.Authentication.AuthenticationException], [Microsoft.ActiveDirectory.Management.ADServerDownException] {
						# catch credential failure and retry
						$credentialSplat = Repair-BuildProcessElevatedCredentialSplat -CredentialRetryCount $CredentialRetryCount -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference

						$CredentialRetryCount++ 

						Continue # retry
					}
				}
				else {
					Write-Verbose "$($ADComp.DistinguishedName) is in a child OU of $($buildInfo.OU) - not moving"
				}
				$moveSuccess = $true
			}
		
		}
		catch {
			if (-not $remoteMachine) {

				$msg = $DeviceDeploymentDefaultConfig.TicketInteraction.GeneralErrorMessage

				New-BuildProcessError -errorObj $_ -message "AD Commands have Failed. Please manually check that the device is in the listed OU and groups. This has not effected other parts of the build process." -functionName "Invoke-DeviceADCommands" -buildInfo $buildInfo -debugMode -ErrorAction Stop
			}
			else {
				$errorList += $_
			}
		}
		finally {
			if (-not $remoteMachine) {
				# add note to ticket that AD commands completed
				$buildInfo.buildState = $ADCommandsCompletedString
				Write-DeviceBuildStatus -BuildInfo $buildInfo -message $msg			
			}
		}
	}
	end {
		if ($remoteMachine -and $errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}
# SIG # Begin signature block
# MIIPXQYJKoZIhvcNAQcCoIIPTjCCD0oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDOcpEbxDHNFV+u
# NX3NKhKKf3HHCsP7mGiunViBkxsoBqCCDJ0wggXxMIIE2aADAgECAhM2AAAABHxF
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
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgYUCEuahFChnwdPWZ71PCppXq
# KtlEu/6BGAl4sayfoxcwDQYJKoZIhvcNAQEBBQAEggEAOBRIlIZwAw7aSXF0TB1C
# 8Oa0TaUN5XbOGEmdmSltU7LT3qHx1/U03uj3hW2RDWYZj211bjp8eUhOiY4ONTyH
# 6JEDMA60MPBYhGFzz1fYi8q1ckREV11OlDXzlJvrmi2k557UcYKahoPwY/v6xXjM
# NBaHFnTGllcGJ4TAuRWBR99C2e35r4TunumYSVRX6esuoSS9WpnsOJUSp/tNmDdF
# eUzTVYarUhbjh0l5lm//o8+WvdneADLT1MxkSFZFOmUnbALqRqufNoX1bhU5CmEJ
# bkJFQRX2gwDadzDmc1PT7DiD2vxf3DQ4+rb29XP8wiqfj6jCiTP1Ka/WJPcLaRLe
# RA==
# SIG # End signature block
