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
	Import-Module ActiveDirectory

	$buildInfo = Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData -ErrorAction SilentlyContinue
}
# BeforeDiscovery {
# 	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"
# 	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"


# }

Describe "Securely utilising privildeged credentials" {
	Context "Handling concurrent credential reset for delete ad dupe" {
		It "Deleted AD Duplicate Gets new credentials and continues on without erroring" {
			Write-Host "This test required manual oversight. Login with invaild creds. You should be reprompted enter correct ones, then test should pass" -BackgroundColor Cyan
			Register-BuildProcessElevatedCredentailsScriptWide -whatif -verbose

			{$buildInfo | Remove-DeviceADDuplicate -WhatIf -verbose -pauseTime 0} | Should -not -Throw

		}
		It "errors when creds are wrong 3 times" {
			Write-Host "This test required manual oversight. Login with invaild creds. You should be reprompted keep entering wrong deails, the function shuld error, test should pass" -BackgroundColor Cyan
			Register-BuildProcessElevatedCredentailsScriptWide -whatif -verbose

			{$buildInfo | Remove-DeviceADDuplicate -WhatIf -verbose -pauseTime 0 -ErrorAction Stop} | Should -Throw
		}
	}
	Context "Handling concurrent credential reset in invoke-adcommands" {
		It "Gets new credentials and continues on without erroring" {
			Write-Host "This test required manual oversight. Login with invaild creds. You should be reprompted enter correct ones, then test should pass" -BackgroundColor Cyan
			Register-BuildProcessElevatedCredentailsScriptWide -whatif -verbose

			{$buildInfo | Invoke-DeviceADCommands -WhatIf -verbose -Debug} | Should -not -Throw

		}
		It "errors when creds are wrong 3 times" {
			Write-Host "This test required manual oversight. Login with invaild creds. You should be reprompted keep entering wrong deails, the function shuld error, test should pass" -BackgroundColor Cyan
			Register-BuildProcessElevatedCredentailsScriptWide -whatif -verbose

			{$buildInfo | Invoke-DeviceADCommands -WhatIf -verbose -ErrorAction Stop} | Should -Throw
		}
		It "doesn't effect flow of other error handling" {
			$ThisbuildInfo = Get-FreshAsset -Name TCL001402 | Get-DeviceBuildData -ErrorAction SilentlyContinue
			$ThisbuildInfo.AssetID = "Some Garbage"
			$ThisbuildInfo.Hostname = "TCL001629"

			
			{$thisbuildInfo | Invoke-DeviceADCommands -WhatIf -verbose} | Should -not -Throw
		}
	}
}
