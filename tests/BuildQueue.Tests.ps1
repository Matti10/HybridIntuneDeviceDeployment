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
	Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"
	Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"

	Set-FreshAPIKey -API_Key (Unprotect-String -encryptedString "AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAzAHtRA5HSkKHYFaSWBLfagAAAAACAAAAAAADZgAAwAAAABAAAAAC/qYwxhMfoyxy5QRmZbQXAAAAAASAAACgAAAAEAAAAPl+NPlquKeV/rY0/dxPL54YAAAApGYk+XDDktyVSHA0822U36GsRkAEta95FAAAACVrQYzGoe75lD1B8IX9Lf9SK0ub")

}

Describe "Data in Fresh" -ForEach @(
	# "TCL001046","TCL001168","TCL001369","TCL001113","TCL001497","TCL001567","TCL000753","TCL001463","TCL001518","TCL000709","TCL001169","TCL001007","TCL001180","TCL001649","TCL001306","TCL000668","TCL001337","TCL001157","TCL001401","TCL001096","TCL000992" | % {Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_) -ErrorAction SilentlyContinue}
	"TCL001046" | % {Get-DeviceBuildData -freshAsset (Get-FreshAsset -name $_) -ErrorAction SilentlyContinue}
)  {
	Context "Gettings & Converting data from build queue" {
		It "correctly converts data" {
			$write = Write-DeviceBuildQueue -buildInfo $_

			$records = Get-FreshCustomObjectRecords -objectID "11000002434"

			$read = ($records | ? {$_.bo_display_id -eq $write.recordid} | Convert-BuildQueueToBuildData)
			$write.freshAsset = $read.freshAsset

			$writeAttrs = $write | Get-Member | ? {$_.MemberType -like 'NoteProperty'}
			$readAttrs = $read | Get-Member | ? {$_.MemberType -like 'NoteProperty'}

			$readAttrs | Should -be $writeAttrs

			$write | % {
				$read.$_ | Should -be $write.$_
			}

		}
	}
	Context "Setting Data to BuildQueue" {
		It "Creates a record if there isn't already a record for the current build" {
			$buildInfo = $_

			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			$result.Recordid | Should -not -BeNullOrEmpty

			Remove-FreshCustomObjectRecord -objectID "11000002434" -recordID $result.recordID

		}

		It "Updates a record if there is a record for the current build" {
			$buildInfo = $_


			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			$result.Recordid | Should -not -BeNullOrEmpty

			Remove-FreshCustomObjectRecord -objectID "11000002434" -recordID $result.recordID
			
		}
	}
    Context "Testing if devices have checked in" {
		It "returns true when check in is valid" {
			Write-Host "$_"
			$buildInfo = $_
			
			$result = Write-DeviceBuildQueue -buildInfo $buildInfo

			$test = (Test-DeviceCheckIn -buildInfo $result) 
			$test| Should -BeTrue

			Remove-FreshCustomObjectRecord -objectID "11000002434" -recordID $result.recordID
		}

		It "returns true when check in is valid" {
			Write-Host "$_"
			$buildInfo = $_
			
			$test = Test-DeviceCheckIn -buildInfo $buildInfo
			$test | Should -BeTrue

		}
	}
}