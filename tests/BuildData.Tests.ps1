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

}
BeforeDiscovery {
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"
}

Describe "Data in Fresh" {
	Context "Getting Data from Fresh Asset" {
		It "Retrives expected build data from Fresh Asset" -foreach @(
			"TCL001629"
		){
			Connect-KVUnattended | Out-Null

			$freshAsset = Get-FreshAsset -name $_
			$result = Get-DeviceBuildData -freshAsset $freshAsset
		

			$result.AssetID | Should -Be $_
			$result.hostname | Should -be "$(hostname)"
			$result.build | Should -not -BeNullOrEmpty
			$result.OU | Should -not -BeNullOrEmpty
			$result.groups | Should -not -BeNullOrEmpty
			$result.buildState| Should -not -BeNullOrEmpty
			$result.serialNumber | Should -be $freshAsset.type_fields.serial_number_11000673046
			$result.userEmail | Should -not -BeNullOrEmpty
		}
	}

}