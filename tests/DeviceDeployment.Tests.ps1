BeforeAll {
    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Mwinsen\Script-Dev*" -or "" -eq $PSCommandPath ) {
        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\DeviceGrouping\module-dev\TriCare-DeviceManagment\TriCare-DeviceManagment.psm1"  -Force
    } else {
        Import-Module TriCare-DeviceManagment | Out-Null
    }

    $config = Get-Content -Path "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\DeviceGrouping\config\config.json" | ConvertFrom-Json


}
Describe "General Setup" {
    Context "Default Config"{
        It "Sets default config varible" {
			Get-DeviceDeploymentDefaultConfig | Should -Not -BeNullOrEmpty
		}
    }
}

