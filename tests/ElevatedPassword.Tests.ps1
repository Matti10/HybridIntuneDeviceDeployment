BeforeAll {

    Set-StrictMode -Version 2.0

	Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
	Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force

	$config = Get-DeviceDeploymentDefaultConfig

	Connect-KVUnattended


	function Test-ADCredentials {
		param (
			[string]$username,
			[string]$password
		)
		
		# Convert password to secure string
		$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
		
		# Try to get the AD user
		try {
			$user = Get-ADUser -Identity $username -Credential (New-Object System.Management.Automation.PSCredential($username, $securePassword)) -ErrorAction Stop
			Write-Host "Credentials are valid."
			return $true
		} catch {
			Write-Host "Invalid credentials."
			return $false
		}
	}

}
BeforeDiscovery {
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"		
	# Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"
}

Describe "Resetting Elevated Password" {
    Context "Password is reset in AD and KV" {
		it "Changes password in AD and KV" {

			$wrongPassword = ConvertTo-SecureString -AsPlainText (Get-Password -highEntropy)

			Set-AzKeyVaultSecret -VaultName $config.Security.KeyVaultName -Name $config.Security.elevatedPassword_KeyVaultKey -SecretValue $wrongpassword -Verbose

			Set-ADAccountPassword -Identity $config.Security.elevatedUserName -NewPassword $wrongPassword -Reset -Verbose


			$result = & "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\driverScripts\buildProcess-ElevatedPasswordReset.ps1" -Verbose 4>&1


			$newPass = Get-AzKeyVaultSecret -VaultName $config.Security.KeyVaultName -Name $config.Security.elevatedPassword_KeyVaultKey -AsPlainText

			Test-ADCredentials -username $config.Security.elevatedUserName -password $newPass | Should -beTrue
		}
	}
}