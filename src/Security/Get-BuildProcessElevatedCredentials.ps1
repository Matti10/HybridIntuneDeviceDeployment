
# Documentation
<#
.SYNOPSIS
The Test-DeviceBuildExecuted function tests whether a device build was executed successfully or not. 

.DESCRIPTION
This function uses the information stored in a local status file to determine whether a build for a device was executed as expected. It returns 'true' if there is no record of a build in the local status file, and 'false' if the record exists. 

.PARAMETER localStatusFile
The path of the local status file is passed as a parameter to the function (by default, it uses a path defined in $DeviceDeploymentDefaultConfig.BuildStatus.LocalBuildStatusFile).

.INPUTS
This function accepts an input of the path to a local status file.

.OUTPUTS
If it does not find any record of a build in the local status file, it returns 'true'.
Otherwise, if a record exists, it outputs 'false'. 

Falls back to output any errors that may be found in the process of execution.

.EXAMPLE
Test-DeviceBuildExecuted -localStatusFile "path/to/local/status/file"

This will test the build execution status of the device using the information from the given local status file.

#>
function Get-BuildProcessElevatedCredentials {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Declare a parameter that to accept the path to the local status file
		[Parameter()]
		$keyVaultName = $DeviceDeploymentDefaultConfig.Security.KeyVaultName,

		[Parameter()]
		$secretName = $DeviceDeploymentDefaultConfig.Security.elevatedPassword_KeyVaultKey,

		[Parameter()]
		$username = $DeviceDeploymentDefaultConfig.Security.elevatedUserName
	)

	# Begin block executes at the start of the function
	begin {
		# Initialize $errorList as an empty array to store any potential errors
		$errorList = @()
	}
	# Process block executes for each pipeline object passed to the function
	process {
		try {
			if ($PSCmdlet.ShouldProcess("")) {
				$securePassword = ConvertTo-SecureString -String (Get-KVSecret -KeyVault $keyVaultName -Secret $secretName) -AsPlainText -Force
			}
			else {
				$securePassword = Read-Host -AsSecureString -Prompt "Running in Whatif mode, please manaully enter the password for $username"
			}
			
			return New-Object System.Management.Automation.PSCredential($username, $securePassword)
		}
		# Catch any errors and add them to $errorList and display an error message
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	# End block executes after the process block (after all pipeline objects have been processed)
	end {
		if ($errorList.count -ne 0) {
			# If there are any errors, write them all and stop execution
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}