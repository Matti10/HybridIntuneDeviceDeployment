
# Documentation
<#
.SYNOPSIS
This function is used to install device drivers using Dell Command Update.

.DESCRIPTION
The Install-DeviceDellCommandUpdateDrivers function will utilize Dell Command Update to install device drivers to the targeted machine. This function is specifically designed to work with Dell systems. In case the system does not have the Dell Command Update installed or if it is not a Dell system, a verbose message will be displayed.

.PARAMETER softwareLocations
An optional parameter that takes a list of software installation locations. If none is provided, it will use the DellCommandUpdate installation locations defined in the 'DeviceDeploymentDefaultConfig' configuration.

.EXAMPLE
Install-DeviceDellCommandUpdateDrivers

Executes the function with the default DellCommandUpdate installation locations.

.EXAMPLE
Install-DeviceDellCommandUpdateDrivers -softwareLocations "C:\Software"

Executes the function with a custom software location.

.INPUTS
$softwareLocations 
Path to the directory where the software is installed, it is optional.

.OUTPUTS
None. Errors are written to the error stream.

.NOTES
Before running this function, Dell Command Update must be present on the system. Moreover, the account executing the script requires administrative privileges over the system.

#>

function Install-DeviceDellCommandUpdateDrivers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Parameter definition for the software locations.
        [Parameter()]
        $softwareLocations = $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations,

        [Parameter()]
        $buildInfo = ""
    )
    begin {
        # Initialize error list to empty.
        $errorList = @()
    }
    process {
        try {
            # Test if Dell Command Update is installed.
            $commandUpdatePath = Test-DeviceDellCommandUpdate
            if ($commandUpdatePath -ne $false) {
                # Dell Command Update found, display a verbose message and continue with the update.
                Write-Verbose "Running Dell Command Update Driver Updates"
                # Enable the advancedDriverRestore feature.
                & "$commandUpdatePath" /configure -advancedDriverRestore=enable

                # Install the drivers.
                & "$commandUpdatePath" /driverInstall "$(if($VerbosePreference -eq "SilentlyContinue") {"-silent"})"
            } else {
                # Dell Command Update not found, display a verbose message.
                Write-Verbose "Device doesn't have Dell command update installed (probably because it isn't a dell)"
            }
        }
        catch {
            # In case of an error, add it to the error list and write it to the Error Stream.
            $errorList += $_
        }
    }
    end {
        # If there were any errors, stop the process and display the error details.
        if ($errorList.count -ne 0) {
			$errorList | ForEach-Object {
                New-BuildProcessError -errorObj $_ -message "Dell Command Update experinced errors. Please run manually" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
            }
        }
    }  
}

# SIG # Begin signature block
# MIIPXQYJKoZIhvcNAQcCoIIPTjCCD0oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBJh7OtWlhkHguc
# mVSSOFqCpOgUjyCDcyud4iKZkWMoLKCCDJ0wggXxMIIE2aADAgECAhM2AAAABHxF
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
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg/9EUnVUtoVOTo2FPIIMRaDY6
# h19nZ64nNpV5gnYx+54wDQYJKoZIhvcNAQEBBQAEggEATtEpWEfSnHDINYuYpjfk
# aSeZiCMXHSU6CDhhRfzLz1Mnf5aPNp9ZDcmzd7bpkVcxsj5+Nc9B2jyAI/UxFb3Z
# yb1sjUYS3YhCQfpAD4lPMwYfaR1YQ94wk7YarNU6sD5UOoBK3gNHSqcUHd/L+iIb
# ZrOovE4Ca761LEuP4YKa9iK2eHR78rRqfRfuKGnvRDTx9KUmOIjLoOIKIoBGvQBX
# iX4PKiUhp4/PemXFYEB4woeZLqvbvsCaNpK+4WsYvA5r5M01J3nyYtwtgZelJlux
# 1szknIwMhgGv22kqt4g0D7e+eNvs5ksDQ+mLEztAfhja1vX3aitaJZnU5kUDH6Wu
# gA==
# SIG # End signature block
