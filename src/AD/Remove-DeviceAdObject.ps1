# This is a copy paste from TriCare-DeviceManagment. I'm not sure how I feel about this... Right now it seems like a better option than dowloading a whole second module

function Remove-DeviceAdObject {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $buildInfo,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    begin {
        $errorList = @()

        $credentialSplat = Build-CredentialSplat -Credential $Credential
    }
    process {
        try {
            # Get AD Object
            try {
                $AD_Comp = Get-ADComputer -Identity $buildInfo.AssetID -ErrorAction stop @credentialSplat
                                
                if ($null -eq $AD_Comp) {
                    throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new()
                }

                Write-Verbose "AD | SAMNAME: $($AD_Comp.SamAccountName)"

                # Remove Device from AD
                if ($null -ne $AD_Comp) {
                    #get the ad comp (as an object)
                    $compObj = Get-ADObject -SearchBase $AD_Comp.DistinguishedName -Filter {ObjectClass -eq "computer"} @credentialSplat
                    
                    #remove adcomp and all its leaves
                    $compObj | Remove-ADObject -Confirm:$false -verbose:$VerbosePreference -WhatIf:$WhatIfPreference -Recursive @credentialSplat
                    
                }
            } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
                Write-Verbose "$($buildInfo.AssetID) doesn't exist in AD"
            }
        } catch [System.Security.Authentication.AuthenticationException],[Microsoft.ActiveDirectory.Management.ADServerDownException] {
            throw $_ #if its a credential errror, let it get handled by calling function
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
# MIIPYQYJKoZIhvcNAQcCoIIPUjCCD04CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCArBjhETZrTFPQS
# 3jMfIzPVgm3D4GkPtJEkCINEuK73MaCCDKEwggXxMIIE2aADAgECAhM2AAAABHxF
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
# XnTvOC4HoeSy7+jlIlYrMIIGqDCCBZCgAwIBAgITMwAAARJwYSFjJEqp6gABAAAB
# EjANBgkqhkiG9w0BAQsFADBNMRMwEQYKCZImiZPyLGQBGRYDaW50MRkwFwYKCZIm
# iZPyLGQBGRYJdHJpY2FyZWFkMRswGQYDVQQDExJUcmlDYXJlIElzc3VpbmcgQ0Ew
# HhcNMjMxMTA2MDM0MTUxWhcNMjQxMTA1MDM0MTUxWjAYMRYwFAYDVQQDEw1TZWFu
# IENhbGxhaGFuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt+OKFpos
# iae/K4L718e30otnYj0IBceSRJY/ZcnGwcVvypo3y/m9LrwVEGhI9Bue/iif9wND
# xbCb8ap8Akw9D9iFflmu/z4PnmRqiExRDYWatotCOI3nARjYqTEYEKiA4ZCCWreM
# vZA3mKdadoMgnj4x9aVoSwgjbGUrIG/U/DuNd/0get73KkbYgO1Me4bi/R8IAjvw
# KYrf1V6jru7+7a+cKEiBMkvUuFyIRWk4YGnnEXDr+MTgdWQaMJLQMiPXTDr3/+SM
# +GFNsGqxOBh0KCTmU4iw4Ex7+m8+8WahIxIbVenuzX99bjuawN/NEPJMmLtNJ62l
# MWNfRra/S9K6LQIDAQABo4IDtDCCA7AwPQYJKwYBBAGCNxUHBDAwLgYmKwYBBAGC
# NxUIhJ6/IYST7RuH7ZkXhuSWOITI4xwwgpXcIoGa7QUCAWQCAQIwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYI
# KwYBBQUHAwMwHQYDVR0OBBYEFBMZv8dtgIX5eIosNVjmIOYRb1DDMB8GA1UdIwQY
# MBaAFIh5bmpKEbIS7fnBDu94IwiXIb/CMIIBIwYDVR0fBIIBGjCCARYwggESoIIB
# DqCCAQqGP2h0dHA6Ly9jcnQudHJpY2FyZS5jb20uYXUvQ2VydEVucm9sbC9UcmlD
# YXJlJTIwSXNzdWluZyUyMENBLmNybIaBxmxkYXA6Ly8vQ049VHJpQ2FyZSUyMElz
# c3VpbmclMjBDQSxDTj1UQy1BRS1QLUNBSS0wMSxDTj1DRFAsQ049UHVibGljJTIw
# S2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz10
# cmljYXJlYWQsREM9aW50P2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9v
# YmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCCATkGCCsGAQUFBwEBBIIB
# KzCCAScwawYIKwYBBQUHMAKGX2h0dHA6Ly9jcnQudHJpY2FyZS5jb20uYXUvQ2Vy
# dEVucm9sbC9UQy1BRS1QLUNBSS0wMS50cmljYXJlYWQuaW50X1RyaUNhcmUlMjBJ
# c3N1aW5nJTIwQ0EoMSkuY3J0MIG3BggrBgEFBQcwAoaBqmxkYXA6Ly8vQ049VHJp
# Q2FyZSUyMElzc3VpbmclMjBDQSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2Vy
# dmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz10cmljYXJlYWQs
# REM9aW50P2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0
# aW9uQXV0aG9yaXR5MDcGA1UdEQQwMC6gLAYKKwYBBAGCNxQCA6AeDBxTZWFuLkNh
# bGxhaGFuQHRyaWNhcmUuY29tLmF1MFAGCSsGAQQBgjcZAgRDMEGgPwYKKwYBBAGC
# NxkCAaAxBC9TLTEtNS0yMS0zMTQyMzU3NDI1LTM0MzQ1MTAyNzYtMzE3MzE4MzA5
# Ny0xNTc2NjANBgkqhkiG9w0BAQsFAAOCAQEAWtTjrbwf+2xkfG1pel5D103DbDKk
# HZgD21FOUAOY+S4ob6LxngbvPZbgr96xckdSRvPOuM6n6lExAeuMHIyQZIKP/lED
# h9RwOWUEHVN3XqbfcXQaQ8EONDM7/CWAR8pIEgrN09ltnFrZY/oXSrAnfHhr11PX
# f/SBiI3LpqYEbCwX1wss3JvMiut2FpxUb+gIN/eUE4aoFjOZC/VEOPndwKW0T1Wq
# paXnmQAYeRrYuIwq0dC2Vra6NZ5pOvTyBNuBfCbiwj1juP72R5hqJuf8KTy28LK2
# JKGATA49O1DWxGJpXyn39BWeVxFUsAVLVt6EAETEvv7Ubu6fiRyGO9GqnTGCAhYw
# ggISAgEBMGQwTTETMBEGCgmSJomT8ixkARkWA2ludDEZMBcGCgmSJomT8ixkARkW
# CXRyaWNhcmVhZDEbMBkGA1UEAxMSVHJpQ2FyZSBJc3N1aW5nIENBAhMzAAABEnBh
# IWMkSqnqAAEAAAESMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILq/dbYaTkWml4gR0Ojo
# PeVKYzA05RFqfOf6nUI5e65AMA0GCSqGSIb3DQEBAQUABIIBAJkQkwZaTBq6oU75
# RsL6Ja7rKebL+24GTNanIgIFlM2SQgbYox3CKRF9fpBwUNi1FxfJ7LoQ1YnC5zoB
# qrJnKt4V2sfSMRbJwf1HleQivGTWd83XfpqhG0u+ibU/m/EPwfymZUiBNRZyfY6X
# HzvM9xaExuQ1ig1GtR0PmVxm03hN/+zMyoTcxhlu4E0qZEN3PkYBz8n4uvPDPQkr
# gh0/eI5Hqt0tqaFPRkB4wcU5hbIL2OEiwZs5fgBCxpRoWTZNjnvm6yFq4+r5NIUY
# kvSKfKKvB8BCAE5yWoQ+SJexBXST/W6/mRZwfQ/wpCxixWFV74ZhXP63BL7e9UIn
# 0gkf9kE=
# SIG # End signature block
