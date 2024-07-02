Describe "Generic" {
    Context "Device Correlation" {
        It "Gets correct facility"  -ForEach @($config.Deployment.locationCorrelation) {
            "$((Find-DeviceCorrelationInfo -build "Head Office" -facility $_.freshID).facilityCorrelation)" | Should -be "$($_)"
        }

        It "Gets correct facility"  -ForEach @($config.Deployment.buildTypeCorrelation) {
            "$((Find-DeviceCorrelationInfo -build $_.buildType -facility "11000342556").buildCorrelation)" | Should -be "$($_)"
        }

        It "Errors if no facility or build are found" -ForEach @(
            {Find-DeviceCorrelationInfo -build "Head Office" -facility "someNonExistentFacility" -errorAction Stop},
            {Find-DeviceCorrelationInfo -build "SomeNonExistenBuild" -facility "someNonExistentFacility" -errorAction Stop},
            {Find-DeviceCorrelationInfo -build "SomeNonExistenBuild" -facility "11000342556" -errorAction Stop}
        ) {
            {& $_} | Should -Throw
        }
    }
}

Describe "Local Commands" {
    Context "Blocking Local Shutdown" {
        It "Creates the blocker job" {
            $job = Block-DeviceShutdown

            (Get-Job).name| Should -Contain "Block-DeviceShutdown"

            Get-Job | ? {$_.Name -like "*Block-DeviceShutdown*"} | Stop-Job
        }

        It "Stops the blocker job" {
            $job = Block-DeviceShutdown

            (Get-Job).name| Should -Contain "Block-DeviceShutdown"

            Unblock-DeviceShutdown

            (Get-Job | ? {$_.Name -eq "Block-DeviceShutdown"}).state | % {$_| Should -be "Stopped"}

        }
    }
    Context "Getting Local Data" {
        it "Gets local data " {
            # This only works on a non-virtual machine
            
            # $systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
            # $model = $systemInfo.model
            # $hostname = $systemInfo.Name
            # $serial =  (Get-CimInstance -ClassName win32_bios).SerialNumber          
            
            # Get-DeviceLocalData
        }
    }

    Context "GPupdates" {
        It "doesn't error and creates reg key" {
            {Invoke-GPUpdate -waitTime 0} | Should -not -Throw
            (Get-ItemProperty -Path $config.Generic.RunOnceRegistryPath | Get-Member).Name | Should -Contain "GPUpdate"

            Remove-ItemProperty -Path $config.Generic.RunOnceRegistryPath -Name GPUpdate
        }

    }
}


Describe "Windows Updates" {
    Context "Installing Preqs" {
        It "Installs NuGet if not installed - This only works on device that don't already have nuget" {

            If ((Get-PackageProvider).Name -notContains "nuget") {
                Initialize-DeviceWindowsUpdate -whatIf -verbose *>&1 | Should -beLike "*Installing*"
            } else {
                Initialize-DeviceWindowsUpdate -whatIf -verbose *>&1 | Should -not -beLike "*Installing*"
            }
        }


        It "Installs NuGgett if not installed - This only works on device that don't already have nuggett" {

            "$(Initialize-DeviceWindowsUpdate -packageProviderName "nuggett" -whatIf -verbose -errorAction SilentlyContinue *>&1)" | Should -beLike "*Installing*"
        }


        It "Installs PSWindows update if not installed" {
            Uninstall-Package -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue

            Initialize-DeviceWindowsUpdate

            (Get-Package).Name | Should -Contain "PSWindowsUpdate"
        }
    }
    
    Context "Installing windows updates - This needs to be tested on a new machine..." {
        It "Installs updates" {
            Update-DeviceWindowsUpdate 
        }
    }
}

Describe "Bloatware Removal" {
    Context "As above" {
        It "searches all expected locations" {
            $searchLocs = "*HKLM*Uninstall*","*HKEY_USERS\.DEFAULT*Uninstall*","*HKEY_USERS\S-1-5-19*Uninstall*","*HKEY_USERS\S-1-5-20*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-14532*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-14532_Classes*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-18187*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-18187_Classes*Uninstall*","*HKEY_USERS\S-1-5-80-1184457765-4068085190-3456807688-2200952327-3769537534*Uninstall*","*HKEY_USERS\S-1-5-80-1184457765-4068085190-3456807688-2200952327-3769537534_Classes*Uninstall*","*HKEY_USERS\S-1-5-80-1835761534-3291552707-3889884660-1303793167-3990676079*Uninstall*","*HKEY_USERS\S-1-5-80-1835761534-3291552707-3889884660-1303793167-3990676079_Classes*Uninstall*","*HKEY_USERS\S-1-5-18*Uninstall*"

            $result = "$(Remove-DeviceBloatware -verbose -whatif -errorAction "SilentlyContinue" *>&1)"

            foreach ($loc in $searchLocs) {
                $result | Should -Belike "*Searching$loc"
            }
            
        }

        It "Removes correct software without erroring (test on real device)" {
            Remove-DeviceBloatware -verbose -errorAction SilentlyContinue
        }
    }
}

Describe "Dell Command Update" {
    Context "ee" {
        It "Discovers Command update if its installed" {
            if ("$(((Get-ChildItem Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty) | Select DisplayName).DisplayName)" -like "*Dell Command*") {
                Test-DeviceDellCommandUpdate | Should -not -be $false
            } else {
                Test-DeviceDellCommandUpdate | Should -be $false
            }
        }

        It "Updates drivers correctly (must be tested on dell device)" {
            $result = "$(Invoke-DeviceDellCommandUpdateUpdates *>&1)"

            if ( $result -like "*The program exited with return code: 1*") {
                $result | Should -beLike "*The program exited with return code: 1*"
            } else {
                $result | Should -beLike "*The program exited with return code: 0*"
            }
        }
    }
}

Describe "Intune Sync" {
    Context "Intune Sync" {
        It "Errors when company portal isnt installed (will only pass on DWDV or brand new machines)" {
            {Invoke-DeviceCompanyPortalSync -errorAction Stop} | Should -Throw
        }

        It "Starts the correct task when company portal is installed" {
            Invoke-DeviceCompanyPortalSync

            (Get-ScheduledTask | Where-Object {$_.TaskName -eq $syncTaskName}).state | Should -be "Running"
        }
    }
}

Describe "Cleanup" {
    Context "Cleanup" {
        It "Doesn't remove log files" {
            New-Item -Path "$($config.Generic.buildPCRootPath)\Modules\SomeTestModule\someGarbage.ps1"  -force -Value "someTestValue"
            New-Item -Path "$($config.Logging.buildPCLogPath)\someLog.txt" -Value "someTestValue" -force 
            New-Item -Path "$($config.Generic.buildPCRootPath)\someRandom.txt" -Value "someTestValue" -force 

            Remove-DeviceDeploymentTempData -verbose

            $items = Get-ChildItem -Path $config.Generic.buildPCRootPath -Recurse -Depth 100

            $items | Should -not -BeNullOrEmpty
            $items | % {
                $_.FullName | Should -beLike "*$($config.Logging.buildPCLogPath)*"
            }
        }
    }
}

Describe "Device User Communication" {
    Context "Creating Popups" {
        It "creates a popup" -ForEach @(
            $config.DeviceUserInteraction.messageBoxConfigurations.Exclamation,
            $config.DeviceUserInteraction.messageBoxConfigurations.Retry,
            $config.DeviceUserInteraction.messageBoxConfigurations.Information
        ) {
            {Show-DeviceUserMessage -Message "Test" -Title "test" -messageBoxConfigCode $_} | Should -not -Throw
        }
    }
}