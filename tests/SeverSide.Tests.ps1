BeforeAll {

    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
    } else {
		Import-Module TriCare-Common | Out-Null
		Import-Module .\TriCare-DeviceDeployment | Out-Null
    }

}

Describe "Getting Data from Fresh" {
    Context "Testing if devices have checked in" {
		It "returns valid build GUID when check in is valid" {
			$result = Test-DeviceTicketCheckIn -conversations (Get-FreshTicketConversations -ticketID 101629) 
			$result | Should -not -be "99VVK63-133640215375952942"
			$result | Should -BeLike "*99VVK63-*"
		}

		It "returns false when device hasnt checked in" {
			Test-DeviceTicketCheckIn -conversations (Get-FreshTicketConversations -ticketID 101631) | Should -BeFalse
		}
	}
}

