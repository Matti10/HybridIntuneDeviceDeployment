function Get-DeviceBuildOU {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory)]
        [Object]$build,

        [Parameter(Mandatory)]
        [Object]$facility,

        [Parameter()]
        $baseOU = $DeviceDeploymentDefaultConfig.Generic.DeviceOUScope
    )

    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("$build & $facility")) {
            try {
                #------------------------------ resolve OU from facility and build --------------------------------------
				$baseOU = "$($build.OU),$baseOU"
				$baseOU = "$($facility.location),$(if($build.hasDepartment){$facility.dept}),$baseOU"
				
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
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}