BeforeAll {

    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceManagment\TriCare-DeviceManagment.psm1" -Force
    } else {
		Import-Module TriCare-Common | Out-Null
		Import-Module .\TriCare-DeviceDeployment | Out-Null
		Import-Module .\TriCare-DeviceManagment | Out-Null
    }

	Set-FreshAPIKey -API_Key (Unprotect-String -encryptedString "AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAzAHtRA5HSkKHYFaSWBLfagAAAAACAAAAAAADZgAAwAAAABAAAAAC/qYwxhMfoyxy5QRmZbQXAAAAAASAAACgAAAAEAAAAPl+NPlquKeV/rY0/dxPL54YAAAApGYk+XDDktyVSHA0822U36GsRkAEta95FAAAACVrQYzGoe75lD1B8IX9Lf9SK0ub")

}
BeforeDiscovery {
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"		
	
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"

	# Set-FreshAPIKey -API_Key (Unprotect-String -encryptedString "AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAzAHtRA5HSkKHYFaSWBLfagAAAAACAAAAAAADZgAAwAAAABAAAAAC/qYwxhMfoyxy5QRmZbQXAAAAAASAAACgAAAAEAAAAPl+NPlquKeV/rY0/dxPL54YAAAApGYk+XDDktyVSHA0822U36GsRkAEta95FAAAACVrQYzGoe75lD1B8IX9Lf9SK0ub")
}

Describe "Retrying" {
    Context "Retry invoked" {
		It "calls the correct path" {
			$path = Invoke-BuildProcessRetry -whatif

			$path | Should -beLike "*TriCare-DeviceDeployment\src\Driver Scripts\BuildPC\buildProcess-OOBE-Interactive.ps1"
			{Test-Path $path} | Should -BeTrue
		}
	}
	Context "Wipe invoked" {
		It "calls systemreset" {
			$path = Invoke-BuildProcessRetry -whatif

			$path | Should -beLike "*systemreset.exe"
		}
	}
	Context "cancel called" {
		It "does nothing" {
			$path = Invoke-BuildProcessRetry -whatif

			$path | Should -beLike "Continuing to windows"
		}
	}
}