BeforeAll {

	Set-StrictMode -Version 2.0

	<# --- Import TriCare-Common --- #>
	if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "H:\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "H:\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
	}
 else {
		Import-Module TriCare-Common | Out-Null
		Import-Module .\TriCare-DeviceDeployment | Out-Null
	}

}
# BeforeDiscovery {
# 	Import-Module "H:\Script-Dev\TriCare-Common\TriCare-Common.psm1"		
	
# 	Import-Module "H:\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"
# }

Describe "Intune" {
	Context "Getting Intune ID" {
		It "Gets intune ID (this may only work on clients)" {
			{ Get-DeviceIntuneID -ErrorAction Stop } | Should -Throw
		}
	}

	Context "Cleaning up otherdevices" {
		It "removes all devices other than the correct device" -ForEach @(
			@{serial="007000772353";correctID="1818e6e0-c20e-404d-8932-fe5b2aa19eb2"},
			@{serial="021568611453";correctID="60b43f4f-5a57-4940-958d-1ba6a2647558"},
			@{serial="021969114353";correctID="48befad9-0d67-4b38-b202-b93188a7ef01"},
			@{serial="059812381353";correctID="24e4296f-fb1d-42c6-ad45-c2fe73eee2b5"},
			@{serial="075819593753";correctID="55722adf-6306-4d63-902a-d444caabdf41"},
			@{serial="0F00GSJ220801J";correctID="d3873ed1-9f1c-4594-a8ec-426d27064f04"},
			@{serial="3JVZVV2";correctID="d7f93d69-2c26-4da9-91a8-18464734afb6"},
			@{serial="99VVK63";correctID="df04b49a-87b8-40ba-b2c1-51c0abaafa9f"},
			@{serial="JGRBQL3";correctID="491cd7a6-e54b-4a94-a62e-dcef1f979103"}
		) {

			$buildInfo = New-BuildInfoObj -assetID "someAssetID" -recordID "69" -freshAsset "e" -OU "e" -groups "e","g" -serialNumber $serial -intuneID $correctID -type "sdff" -build 'e'

			$out = "$(Remove-DeviceIntuneDuplicateRecords -buildInfo $buildInfo -whatif -verbose *>&1)"
			$out | Should -beLike "*Removing*"
			$out | Should -not -beLike "*$correctID*"
		}
		It "actually removes them" -ForEach @(
			@{serial="007000772353";correctID="1818e6e0-c20e-404d-8932-fe5b2aa19eb2"}
			@{serial="021568611453";correctID="60b43f4f-5a57-4940-958d-1ba6a2647558"}
			@{serial="021969114353";correctID="48befad9-0d67-4b38-b202-b93188a7ef01"},
			@{serial="059812381353";correctID="24e4296f-fb1d-42c6-ad45-c2fe73eee2b5"},
			@{serial="075819593753";correctID="55722adf-6306-4d63-902a-d444caabdf41"},
			@{serial="0F00GSJ220801J";correctID="d3873ed1-9f1c-4594-a8ec-426d27064f04"},
			@{serial="3JVZVV2";correctID="d7f93d69-2c26-4da9-91a8-18464734afb6"},
			@{serial="99VVK63";correctID="df04b49a-87b8-40ba-b2c1-51c0abaafa9f"},
			@{serial="JGRBQL3";correctID="491cd7a6-e54b-4a94-a62e-dcef1f979103"}
		) {

			$buildInfo = New-BuildInfoObj -assetID "someAssetID" -recordID "69" -freshAsset "e" -OU "e" -groups "e","g" -serialNumber $serial -intuneID $correctID -type "sdff" -build 'e'

			Remove-DeviceIntuneDuplicateRecords -buildInfo $buildInfo -verbose

		}
	}
}