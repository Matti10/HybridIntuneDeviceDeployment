
Start-Transcript -path "C:\Intune_Setup\buildProcess\Logs\buildProcessV3\elevatedPasswordReset-$(Get-Date -format "ddMMyyyyhhmmss").log"

try {
	#------------------------------------------------ Setup ------------------------------------------------# 
	Import-Module TriCare-Common
	Import-Module TriCare-DeviceDeployment

	$config = Get-DeviceDeploymentDefaultConfig

	Connect-KVUnattended

	#------------------------------------------------ Main ------------------------------------------------# 
	#try resetting the password up to 5 times
	for ($i = 0; $i -le 5; $i++) {
		try {
			$password = ConvertTo-SecureString -AsPlainText (Get-Password -highEntropy)
		
			Set-ADAccountPassword -Identity $config.Security.elevatedUserName -NewPassword $password -Reset -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference

			# break if it doesn't error
			break
		} catch [Microsoft.ActiveDirectory.Management.ADPasswordComplexityException] {
			Write-Verbose "Password did't meet requirement, regenerating"

			if ($i -ge 5) {
				Write-Error -Message "Password reset has failed to meet length or complexity requirements $i times. Please investigate. `nFull error: $_" -ErrorAction Stop
			}
		}
	}
	
	# Update Password in KV
	Set-AzKeyVaultSecret -VaultName $config.Security.KeyVaultName -Name $config.Security.elevatedPassword_KeyVaultKey -SecretValue $password -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference

} catch {
	New-BuildProcessError -errorObj $_ -message "There has been an error in the build processes elevated account password reset, please see the below output:`n$_" -functionName "Build Process Elevated Password Reset" -ErrorAction "Stop"
}