function Invoke-DeviceDellCommandUpdateUpdates {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $softwareLocations = $DeviceDeploymentDefaultConfig.DellCommandUpdate.installLocations

    )

    begin {
        $errorList = @()
    }
    process {
		try {
            $commandUpdatePath = Test-DeviceDellCommandUpdate
            if ($commandUpdatePath -ne $false) {
                
                Write-Verbose "Running Dell Command Update Software Updates"

                #scan for updates
                & "$commandUpdatePath" /scan "$(if($VerbosePreference -eq "SilentlyContinue") {"-silent"})"

                #scan for updates
                & "$commandUpdatePath" /applyUpdates "$(if($VerbosePreference -eq "SilentlyContinue") {"-silent"})"
                
            } else {
                Write-Verbose "Device doesn't have Dell command update installed (probably because it isnt a dell)"
            }
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