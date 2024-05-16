function Get-DeviceBuildOU {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [string]$build,

        [Parameter(Mandatory)]
        [string]$facility,

        [Parameter()]
        $baseOU = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope,

        [Parameter()]
        $buildTypes = $DeviceDeploymentDefaultConfig.Deployment.buildTypeCorrelation,

        [Parameter()]
        $facilities = $DeviceDeploymentDefaultConfig.Deployment.locationCorrelation
    )

    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("$build & $facility")) {
            try {
                #------------------------------ resolve OU from facility and build --------------------------------------
                $hasDepartment = $true

                # add to 'build' level of OU
                foreach ($buildType in $buildTypes) {
                    if ($build -eq $buildType.buildType) {
                        #start building ou
                        $baseOU = "$($buildType.OU),$baseOU"
                        $hasDepartment = $buildType.hasDepartment
                        break
                    }
                }
    
    
                #add to facility level of OU and read AVM system
                foreach ($location in $facilities) {
                    if ($facility -eq $location.freshID) {
                        $baseOU = "$($location.location),$(if($hasDepartment){$location.dept}),$baseOU"
                        break
                    }
                }
    
                #fix and ",," left in HO OU's
                while ($baseOU -like "*,,*") {
                    $baseOU = $baseOU -replace ",,", ","
                }

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