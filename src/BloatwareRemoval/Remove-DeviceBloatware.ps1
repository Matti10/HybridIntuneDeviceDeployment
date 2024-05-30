function Remove-DeviceBloatware {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        $softwareToRemove = $DeviceDeploymentDefaultConfig.Bloatware.SoftwareToRemove,

		[Parameter()]
        $registryLocations = $DeviceDeploymentDefaultConfig.Bloatware.registryLocations,
		
		[Parameter()]
		$quietUninstallAttr = $DeviceDeploymentDefaultConfig.Bloatware.quietUninstallAttr,
		
		[Parameter()]
		$loudUninstallAttr = $DeviceDeploymentDefaultConfig.Bloatware.loudUninstallAttr,
		
		[Parameter()]
		$registryRoots = @("HKLM:") + (Get-ChildItem -LiteralPath Registry::HKEY_USERS).PSPath
    )

    begin {
        $errorList = @()
    }
    process {
		try {
			foreach ($registryRoot in $registryRoots) {
				foreach ($registryLocation in $registryLocations) {
					Write-Verbose "Searching $registryRoot$registryLocation"
					Get-ChildItem -Path "$registryRoot$registryLocation"
					| ForEach-Object {
						$properties = $_ | Get-ItemProperty
						foreach ($softwareItem in $softwareToRemove) {
							try {
								$members = $properties | Get-Member
								if ($null -ne $members) {
									if ($members.name -contains $softwareItem.searchAttr) {
										if ($properties."$($softwareItem.searchAttr)" -like $softwareItem.searchString) {
	
											if ($members.name -contains $quietUninstallAttr) {
												Write-Verbose "$quietUninstallAttr found with value $($properties.$quietUninstallAttr)"
												$splitUninstallString = $properties.$quietUninstallAttr.split(" ")
											} elseif ($members.name -contains $loudUninstallAttr) {
												Write-Verbose "$loudUninstallAttr found with value $($properties.$loudUninstallAttr)"
												$splitUninstallString = $properties.$loudUninstallAttr.split(" ")
											} else {
												Write-Verbose "No uninstall string found for object"
											}
	
											#run the uninstaller
											Start-Process -FilePath $splitUninstallString[0] -ArgumentList @($splitUninstallString[1..-1] + $softwareItem.AddtnUninstallArgs) -Verbose:$VerbosePreference -Wait -ErrorAction "Stop" -WhatIf:$WhatIfPreference
										}
									}
								} 
							}
							catch {
								$errorList += $_
								Write-Error $_
							}
						}
					}
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