##################################################################################################
## This script is used to download, install and invoke the latest version of the build process  ##
##                                  from Visual Studio online                                   ##
## (https://dev.azure.com/tricare/TriCare%20PowerShell%20Library/_git/TriCare-DeviceDeployment) ##
##   The script must have zero depencies as it is uploaded and executed as a single ps1 file    ##
##################################################################################################

#---------------------------------------------------- Args ----------------------------------------------------#
[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $debugMode,

    [Parameter()]
    [switch]
    $skipInstalls,

    [Parameter()]
    [bool]
    $devMode = $true, #manually change this depending if you want code to run as dev or not

    [Parameter()]
    [switch]
    $WhatIf
)
try {

    $Verbose = $true
    $ProgressPreference = 'SilentlyContinue'
    #-------------------------------------------------- Defines --------------------------------------------------# 

    #General
    $workingDirectory = "C:\Intune_Setup\buildProcess"
    $fileName = "buildProcessV2.4" 
    $logPath = "C:\Intune_Setup\buildProcess\Logs"
    $bootStrapperLogPath = "$logPath\$fileName\$fileName-$(Get-Date -Format "dd-MM-yyyy-HHmm").log"
    $modulePath = "C:\Program Files\WindowsPowerShell\Modules"
    $DownloadPath = "$workingDirectory\Downloads"
    $buildModuleName = "TriCare-DeviceDeployment"
    $BuildProcessPath = "$modulePath\$buildModuleName\driverScripts\buildProcess-OOBE-Interactive.ps1"

    #Azure/Visual Studio online
    $az_Organisation = "tricare"
    $az_Project = "TriCare%20PowerShell%20Library"
    $az_repositories = @("TriCare-Common",$buildModuleName) # the order of this list matters, TriCare-DeviceDeployment uses tricare common, as a result it must be imported second. Below external modules are imported first for the same reason
    $az_branch = "dev"
    $az_User = "Matt.Winsen"
    $az_token = "j4fqboeaay3ar7ad4fikyajqqpqcdgcyrfccqqxhgjn337ubxura"

    # External Modules
    $remote_dependencies = @(
        @{
            Name = "Az.Accounts"
            Version = "2.13.1"
        },
        @{
            Name = "Az.KeyVault"
            Version = "4.12.0"
        },
        @{
            Name = "Microsoft.Graph.Authentication"
            Version = "2.19.0"
        },
        @{
            Name = "Microsoft.Graph.DeviceManagement"
            Version = "2.19.0"
        }
    )
    $remote_trustedRepositories = @("PSGallery")
    $remote_packageProviders = @("Nuget")

    #AD Module
    $adInstallJobName = "InstallAD"

    # Proxy
    $proxyProcessName = "stAgentUI"

    #----------------------------------------- Start Logging / Init Setup -----------------------------------------#
    Set-StrictMode -Version 2.0 -Verbose

    $startTime = Get-Date
    Start-Transcript -LiteralPath $bootStrapperLogPath -Force
    Set-Location $workingDirectory

    #---------------------------------------------- Local Functions -----------------------------------------------# 
    function Build-SavePath {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(Mandatory,ValueFromPipeline)]
            $Path
        )

        begin {
            $errorList = @()
        }
        process {
            try {
                #this just removes everything after the last "\" from the string"
                $saveFolder = $Path.remove($Path.LastIndexOf("\"),$Path.length-$Path.LastIndexOf("\"))
                if (-not(Test-Path $saveFolder)) {
                    $result = New-Item -Path $saveFolder -ItemType Directory -whatIf:$WhatIfPreference -force
                }

                return $saveFolder
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
    function Test-TricareModuleCheckSum {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(Mandatory,ValueFromPipeline)]
            $moduleRoot,

            [Parameter()]
            $checksumPath = "$moduleRoot\checksum\checksum.json",

            [Parameter()]
            $checksumPs1Path = "$moduleRoot\checksum\checksum.ps1"

        )

        if ($devMode) {
            return $true
        }

        . "$checksumPs1Path"

        return Test-CheckSum -checksumPath $checksumPath -rootPath $moduleRoot -verbose

    }
    function Install-TriCareModules {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter(Mandatory,ValueFromPipeline)]
            $repository,

            [Parameter()]
            $organisation = $az_Organisation,

            [Parameter()]
            $project = $az_Project,
            
            [Parameter()]
            $user = $az_User,
            
            [Parameter()]
            $remoteRepoURL = "https://dev.azure.com/$organisation/$project",

            [Parameter()]
            $token = $az_token,

            [Parameter()]
            $modulePath = $modulePath,
            
            [Parameter()]
            $downloadPath = $downloadPath,

            [Parameter()]
            $branch = $az_branch


        )

        begin {
            $errorList = @()
        }
        process {
            try {
                if ($PSCmdlet.ShouldProcess($repository)) {
                    $i = 0 #itteration counter for checksum loop
                    do { #loop over install until checksum returns true
                        # Base64-encodes the Personal Access Token (PAT) appropriately
                        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
                        
                        $headers = @{
                            'Authorization' = ("Basic {0}" -f $base64AuthInfo)
                            'Content-Type'  = 'application/json'
                        }
                        
                        
                        # Get Repository
                        $listRepoUri = "$remoteRepoURL/_apis/git/repositories?api-version=6.0"
                        $allRepo = Invoke-RestMethod -Uri $listRepoUri -Method GET -Headers $headers -UseBasicParsing
                        $repo = $allRepo.value | Where-Object -FilterScript {$_.Name -match $repository } | Select-Object Id
                        
                        if($null -eq $repo){
                            Write-Error "Can't find the $repository repo"
                        }
                        
                        # Get all items in repo
                        $itemuri = "$remoteRepoURL/_apis/git/repositories/$($repo.id)/items?recursionLevel=Full&includeContentMetadata=true&download=true&versionDescriptor.version=$branch&api-version=6.0"
                        
                        $allItems = Invoke-RestMethod -Uri $itemuri -Method GET -Headers $headers -UseBasicParsing
                        $files = $allItems.value | Where-Object -FilterScript {$_.gitObjectType -eq 'blob'}
                        
                        # Download items
                        $headers += @{"Accept"="application/zip"}
                        $uri = "$remoteRepoURL/_apis/git/repositories/$($repo.id)/blobs?api-version=6.0"
                        $body = $files.objectId | ConvertTo-Json
                        $downloadFile = "$downloadPath\$repository.zip"
                        
                        Build-SavePath -Path $downloadFile | Out-Null
                        Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -UseBasicParsing -Body $body -OutFile $downloadFile
                        
                        Write-Verbose "Expanding $downloadFile" -Verbose:$Verbose
                        Expand-Archive -Path $downloadFile -DestinationPath $downloadPath  -force
    
                        $repoPath = "$modulePath\$repository"
                        
                        #clear repo folder
                        Write-Verbose "Cleaning $repoPath" -Verbose:$Verbose
                        Remove-Item -Path $repoPath -Recurse -Force -ErrorAction SilentlyContinue
    
                        
                        #get each file, and copy it with the correct name to module directory
                        Write-Verbose "Copying Module to $repoPath" -Verbose:$Verbose
                        foreach ($file in $files) {
                            $savePath = "$repoPath$($file.path.Replace("/","\"))"
                            Build-SavePath -Path $savePath | Out-Null
                            Get-Item -path "$downloadPath\$($file.objectId)" | Copy-Item -Destination $savePath -Force
                        }
    
                        # Find the module file and import it
                        Write-Verbose "Importing $repoPath" -Verbose:$Verbose
                        Import-Module (Get-ChildItem -Path $modulePath\$repository | Where-Object {$_ -like "*.psm1"}).FullName -force

                        $i++
                    } while (-not (Test-TricareModuleCheckSum -moduleRoot "$modulePath\$repository" -ErrorAction "Continue") -and $i -le 3) # retry a max of 3 times
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
    function Wait-DeviceProxyInstall {
        [CmdletBinding(SupportsShouldProcess = $true)]
        param (
            [Parameter()]
            $proxyProcessName = $proxyProcessName
        )

        begin {
            $errorList = @()
        }
        process {
            try {
                if ($PSCmdlet.ShouldProcess((hostname))) {
                    while ($true) {
                        if ($null -ne (Get-Process | Where-Object {$_.Name -like "*$proxyProcessName*"})) {
                            Write-Verbose "Proxy is running continuing (process name: $proxyProcessName)"
                            return
                        }
                        Write-Verbose "Waiting for Proxy to Install (process name: $proxyProcessName)"
                        Start-Sleep -Seconds 5
                    }
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

    #---------------------------------------------- Install Modules ----------------------------------------------# 
    #Install the AD Module - this takes ages so run it as a job in the background
    Start-Job -Name $adInstallJobName -ScriptBlock {
        DISM.exe /Online /Add-Capability /NoRestart /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
    }


    if (-not $skipInstalls) {
        #remote modules
        #add required package providers
        foreach ($packageProvider in $remote_packageProviders) {
            Write-Verbose -Message "Installing $($packageProvider)" -Verbose:$Verbose
            Install-PackageProvider -Name $packageProvider -Confirm:$false -Force
        }

        #allow the repositorys that store the remote_dependencies
        foreach ($repository in $remote_trustedRepositories) {
            Write-Verbose -Message "Allowing $($repository)" -Verbose:$Verbose
            Set-PSRepository -Name $repository -InstallationPolicy Trusted
        }


        #check requisite modules are installed
        $allModules = @()
        foreach ($modules in @((Get-Module -ListAvailable), (Get-InstalledModule))) {
            if ($null -ne $modules) {
                $allModules += $modules.Name
            }
        }

        foreach ($dependency in $remote_dependencies) {
            if ($dependency -notin $allModules) {
                Write-Verbose -Message "Installing $($dependency.Name) version $($dependency.version)" -Verbose:$Verbose
                Install-Module $dependency.Name -Confirm:$false -SkipPublisherCheck -RequiredVersion $dependency.version
            }    
            Write-Verbose -Message "Importing $($dependency.Name) version $($dependency.version)"
            Import-Module $dependency.Name -force
        }

        #Tricare Modules
        $az_repositories | Install-TriCareModules
    }

    #------------------------------------------- Invoke the Build Process ------------------------------------------#
    Invoke-InteractiveDeviceBuildProcess -BuildProcessPath $BuildProcessPath -verbose

    #------------------------------------------------ Stop Logging -------------------------------------------------#
    Write-Host "Execution Time: $((Get-Date)-$startTime)"
    Stop-Transcript
    "## TODO Add Error Handling"
}
catch {
    Write-Error -message "$_" -ErrorAction "Continue"
}
finally {
    exit 0
}

# SIG # Begin signature block
# MIIPXQYJKoZIhvcNAQcCoIIPTjCCD0oCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCsi3q/j+Yomyqu
# dg1nhU/nxBAlkBPhjJWvrs2jhROZDqCCDJ0wggXxMIIE2aADAgECAhM2AAAABHxF
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
# DAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgIzrklIgA65RnfBMEfrehJF1W
# a4aWAQbbqwA5ChuEsQ8wDQYJKoZIhvcNAQEBBQAEggEAXpiT37wJuKvTxk4hoo9o
# Mkm38QWmUZXaniSPMS2gA62mIdILdY5M2Aj+//F72mA8I8Likr9ShV67f3uUIYJr
# wXDu9tpM8jILbwgCwjMfyAKst33mpJKwHyu2Qs6SHtyXPJ92DkDgXE4nJDH8eMGs
# aRPb0wmz8DVECTE9TBhQ6EAFlnmZFefhT9pb2wi+WciYjqWQqMUpK1V+ODyuflcW
# 7ofvo1G39IRiFPc2ft9YKha1Z7Igvdba1rYeHTeufGcV2u1jQ/6+cDAGLfyhiVYn
# Iz+yLII8Bbvxt4JjMRAxfo1zljfvlscE+z8wZwG3Gdyqa5znFTRzbcOYGzpzA70d
# Hw==
# SIG # End signature block
