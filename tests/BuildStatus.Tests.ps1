BeforeAll {

    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "H:\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "H:\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
    } else {
		Import-Module TriCare-Common | Out-Null
		Import-Module .\TriCare-DeviceDeployment | Out-Null
    }

}
BeforeDiscovery {
	Import-Module "H:\Script-Dev\TriCare-Common\TriCare-Common.psm1"		
	
	Import-Module "H:\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"
}

Describe "Local Build Status" -foreach @(
	Get-DeviceBuildData -freshAsset (Get-FreshAsset -name TCL001629)
) {
	Context "Setting local status" {
		It "Sets the local status" {

			Write-DeviceBuildStatus -buildInfo $_

			"$(Get-Content C:\Intune_Setup\buildProcess\buildStatus.json | ConvertFrom-JSON)" | Should -beLike "*$($_.GUID)*"
		}
	}
	Context "Getting Local Status" {
		It "retuns null when not set" {
			Remove-Item -Path C:\Intune_Setup\buildProcess\buildStatus.json -Force -ErrorAction SilentlyContinue

			Get-DeviceBuildLocalStatus | Should -BeNullOrEmpty
		}

		It "Gets the local status" {

			Write-DeviceBuildStatus -buildInfo $_

			(Get-DeviceBuildLocalStatus).GUID | Should -be ($_).GUID
		}
	}
	Context "Testing Local Execution" {
		It "retuns null when not set" {
			Remove-Item -Path C:\Intune_Setup\buildProcess\buildStatus.json -Force -ErrorAction SilentlyContinue

			Test-DeviceBuildExecuted | Should -BeTrue
		}

		It "Gets the local status" {

			Write-DeviceBuildStatus -buildInfo $_

			Test-DeviceBuildExecuted | Should -BeFalse
		}
	}
}