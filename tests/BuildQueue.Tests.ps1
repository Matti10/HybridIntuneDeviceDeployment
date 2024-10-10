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
	Context "Setting Data to BuildQueue" {
		It "Creates a record" -foreach @(
			"TCL001629"
		) {

			$buildInfo = Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_)

			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			$result.bo_record_id | Should -not -BeNullOrEmpty
		}
	}
    Context "Testing if devices have checked in" {
		It "returns valid build GUID when check in is valid" {
			
		}
	}
}