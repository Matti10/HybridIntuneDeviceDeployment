function Set-DeviceLocalSettings {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (

	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			try {
				#check if the required langagues are installed
				if ((Get-WinUserLanguageList).LanguageTag -notcontains "en-AU")
				{
		
					try {
						$langs = (Get-InstalledLanguage).LanguageID
						if ($langs -notcontains "en-AU")
						{
							Write-Host "Installing en-AU lang pack"
							Install-Language en-AU -CopyToSettings
						}
						
						if ($langs -notcontains "en-US")
						{
							Write-Host "Installing en-US lang pack"
							Install-Language en-US
						}
							
					}
					catch {
						Write-Error "Language CMDs not found (likely due to windows being out of date)"
					}
				}
				#set language, region, Locale, Input Method, etc to be correct
				Set-WinSystemLocale -SystemLocale en-AU  -ErrorAction "Continue"
				
				Set-WinHomeLocation -GeoId 12  -ErrorAction "Continue"
				
				Set-WinDefaultInputMethodOverride -InputTip "0c09:00000409"  -ErrorAction "Continue"
				
				Set-WinUILanguageOverride -Language en-AU  -ErrorAction "Continue"
				
				Set-Culture -CultureInfo en-AU  -ErrorAction "Continue"
				
				Set-SystemPreferredUILanguage -language en-AU -ErrorAction "Continue"
	
				$langList = New-WinUserLanguageList -Language 'en-AU'
				$langList.add("en-US")
				Set-WinUserLanguageList $langList -Force -Confirm:$false
	
				#run this again to ensure all changes are copied to settings
				Install-Language en-AU -CopyToSettings -ErrorAction "Continue"
			}
			catch {
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})" -ErrorAction Stop
		}
	}	
}