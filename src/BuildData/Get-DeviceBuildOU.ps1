function Get-DeviceBuildOU {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$build,

        [Parameter(Mandatory)]
        [string]$facility,

        [Parameter()]
        $baseOU = "OU=TriCare-Computers,DC=tricaread,DC=int",

        [Parameter()]
        $buildTypes = $DeviceManagmentDefaultConfig.Deployment.buildTypeCorrelation,

        [Parameter()]
        $facilities = $DeviceManagmentDefaultConfig.Deployment.locationCorrelation
    )

    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("$build & $facility")) {
            try {
                #------------------------------ resolve OU from facility and build --------------------------------------
                #base ou Prefix
    
                # add to 'build' level of OU
                foreach ($buildType in $buildTypes) {
                    if ($build -eq $buildType.buildType) {
                        #start building ou
                        $baseOU = "$($buildType.OU),$baseOU"
                        break
                    }
                }
    
    
                #add to facility level of OU and read AVM system
                foreach ($location in $facilities) {
                    if ($facility -eq $location.freshID) {
                        $facility = $location.location.split("=")[1]

                        #if ops build, append ACR/RC accordingly
                        if ($build -eq "Facility Management/Operations") {
                            $baseOU = "$($location.location),$($location.dept),$baseOU"
                        }
                        else {
                            $baseOU = "$($location.location),$baseOU"
                        }
                        break
                    }
                }
    
                #fix and ",," left in HO OU's
                $baseOU = $baseOU -replace ",,", ","

                return $baseOU
            }
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
        }
    }	
}