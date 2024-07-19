BeforeAll {

    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    # if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
    # } else {
	# 	Import-Module TriCare-Common | Out-Null
	# 	Import-Module .\TriCare-DeviceDeployment | Out-Null
    # }

}
BeforeDiscovery {
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"		
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"
}

Describe "ErrorOutput" {
    Context "Works with connection to fresh" {
		it "works" {
			$info = Get-DeviceBuildData -freshAsset (Get-FreshAsset -name TCL001629)
	
			try {
				Get-Content "Z:\thisDoesntExist.txt" -ErrorAction stop
			} catch {
				{New-BuildProcessError -errorObj $_ -message "AD Commands have Failed. Please manually check that the device is in the listed OU and groups. This has not effected other parts of the build process." -functionName "Invoke-DeviceADCommands" -buildInfo $info -debugMode -ErrorAction "Continue"} | Should -not -Throw
			}
		}
	}
}