function Get-DeviceCorrelationInfo {
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
				$buildCorrelation = $null
				$facilityCorrelation = $null

                # add to 'build' level of OU
                foreach ($buildType in $buildTypes) {
                    if ($build -eq $buildType.buildType) {
                        $buildCorrelation = $buildType
                        break
                    }
                }
    
    
                #add to facility level of OU and read AVM system
                foreach ($location in $facilities) {
                    if ($facility -eq $location.freshID) {
						$facilityCorrelation = $location
                    }
                }

                if ($null -eq $buildCorrelation -or $null -eq $facilityCorrelation) {
                    Write-Error "No correlation info could be found for either the build ($build | $buildCorrelation) and/or facility ($facility | $facilityCorrelation)"
                }
            
                return [PSCustomObject]@{
					buildCorrelation = $buildCorrelation
					facilityCorrelation = $facilityCorrelation
				}
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