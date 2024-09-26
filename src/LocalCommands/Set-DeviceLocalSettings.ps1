
# Documentation
<#
.SYNOPSIS
This function changes the language settings of a system to Australian English ("en-AU") and US English ("en-US").

.DESCRIPTION
The Set-DeviceLocalSettings function is used to change the language settings of a system. It will first check if the required languages are installed. If not, it will install them. This applies to the Australian English and US English language packs.

It then sets the sytem locale, home location, input method, UI language override, culture, user language list, system preferred UI language and copies these changes to settings specifically for Australian English. It also adds US English to the User Language List.

.EXAMPLE 
Example of how to use this function:
Set-DeviceLocalSettings

.INPUTS 
No inputs are required.

.OUTPUTS
The function does not return anything but displays error messages if operations fail.

.NOTES
This function requires the 'Install-Language' function to work properly. 
It also requires the 'Hostname' command to work.
Care should be taken to always run this function after updates have been installed, since language CMDs might not be found if windows version is out of date.
#>

function Set-DeviceLocalSettings {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
        [Parameter()]
        $buildInfo = ""
	)

	begin {
		$errorList = @()
	}
	process {
		# Validates if the function should proceed execution
		if ($PSCmdlet.ShouldProcess("$(hostname)")) {
			try {
				# Check if the required languages are installed
				if ((Get-WinUserLanguageList).LanguageTag -notcontains "en-AU")
				{
					try {
						$langs = (Get-InstalledLanguage).LanguageID
						# Adds English (Australia) language, if it's not installed
						if ($langs -notcontains "en-AU")
						{
							Write-Host "Installing en-AU lang pack"
							Install-Language en-AU -CopyToSettings
						}
						# Adds English (US) language, if it's not installed
						if ($langs -notcontains "en-US")
						{
							Write-Host "Installing en-US lang pack"
							Install-Language en-US
						}
					}
					catch {
						Write-Verbose "Language CMDs not found (likely due to windows being out of date)"
						# Reminder to rerun this after updates
					}
				}
                
				# Set system settings for English (Australia)
				Set-WinSystemLocale -SystemLocale en-AU  -ErrorAction "Continue"
				
				Set-WinHomeLocation -GeoId 12  -ErrorAction "Continue"
				
				Set-WinDefaultInputMethodOverride -InputTip "0c09:00000409"  -ErrorAction "Continue"
				
				Set-WinUILanguageOverride -Language en-AU  -ErrorAction "Continue"
				
				Set-Culture -CultureInfo en-AU  -ErrorAction "Continue"
				
				# Adds US English to the user language list
				$langList = New-WinUserLanguageList -Language 'en-AU'
				$langList.add("en-US")
				Set-WinUserLanguageList $langList -Force -Confirm:$false
				
				# Sets preferred UI language to English (Australia)
				Set-SystemPreferredUILanguage -language en-AU -ErrorAction "Continue"
                
				# Copies changes to system settings
				Install-Language en-AU -CopyToSettings -ErrorAction "Continue"
			}
			catch {
				$errorList += $_
				New-BuildProcessError -errorObj $_ -message "Please check language, locale & culture settings before deploying device" -functionName $PSCmdlet.MyInvocation.MyCommand.Name -popup -ErrorAction "Continue" -buildInfo $buildInfo
			}
		}
	}
	end {
		# At the end of process, all errors (if any occurred) are printed
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction "Continue"
		}
	}	
}