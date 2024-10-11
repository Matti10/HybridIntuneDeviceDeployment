BeforeAll {

    Set-StrictMode -Version 2.0
    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
    } else {
		Import-Module TriCare-Common | Out-Null
		Import-Module TriCare-DeviceDeployment | Out-Null
    }

	Set-FreshAPIKey -API_Key (Unprotect-String -encryptedString "AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAzAHtRA5HSkKHYFaSWBLfagAAAAACAAAAAAADZgAAwAAAABAAAAAC/qYwxhMfoyxy5QRmZbQXAAAAAASAAACgAAAAEAAAAPl+NPlquKeV/rY0/dxPL54YAAAApGYk+XDDktyVSHA0822U36GsRkAEta95FAAAACVrQYzGoe75lD1B8IX9Lf9SK0ub")

}
BeforeDiscovery {
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"
}

Describe "Data in Fresh" {
	Context "Setting Data to BuildQueue" -foreach @(
		"TCL001142","TCL001079","TCL001154","TCL001306","TCL000559","TCL001425","TCL001254","TCL001275","TCL001072","TCL001299","TCL000827","tCL001657","TCL000752","TCL001102","TCL000705","TCL000941","TCL000889","TCL001647","TCL001069","TCL000619","TCL001340","TCL001469","TCL000821","TCL001861","TCL000796","TCL000822","TCL001635","TCL001597","TCL001374","TCL000820"
	) {
		It "Creates a record if there isn't already a record for the current build" {

			$buildInfo = Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_)

			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			$result.Recordid | Should -not -BeNullOrEmpty

			throw "use convert function to test, and test that function first"
		}

		It "Updates a record if there is a record for the current build" {

			$buildInfo = Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_)

			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			$result.Recordid | Should -not -BeNullOrEmpty
			throw "use convert function to test, and test that function first"

		}
	}
    Context "Testing if devices have checked in" -ForEach @(
		"TCL001046","TCL001168","TCL001369","TCL001113","TCL001497","TCL001567","TCL000753","TCL001463","TCL001518","TCL000709","TCL001169","TCL001007","TCL001319","TCL001180","TCL001649","TCL001306","TCL000668","TCL001337","TCL001157","TCL000313","TCL000279","TCL001401","TCL000860","TCL001096","TCL000992","TCL000297","TCL000414"
	) {
		It "returns true when check in is valid" {
			$buildInfo = Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_)
			
			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			Test-DeviceCheckIn -buildInfo $result | Should -BeTrue

			Remove-FreshCustomObjectRecord -objectID "11000002434" -recordID $result.recordID
		}

		It "returns true when check in is valid" {
			$buildInfo = Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_)
			
			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			Test-DeviceCheckIn -buildInfo $result | Should -BeTrue

			Remove-FreshCustomObjectRecord -objectID "11000002434" -recordID $result.recordID
		}
	}
}