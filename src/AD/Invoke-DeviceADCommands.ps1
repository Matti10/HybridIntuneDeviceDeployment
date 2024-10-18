
# Documentation
<#
.SYNOPSIS
This function will invoke Active Directory (AD) commands for a specified device. It adds the device to specified AD Groups and moves the device to a correct Organizational Unit (OU).

.DESCRIPTION
The Invoke-DeviceADCommands function first attempts to find an AD Computer object by its AssetID. If the object cannot be found by AssetID, it will then try to identify it by the Hostname. If both methods fail, an error message will be written.

Once the AD Computer object is identified, the function will add it to the specified AD Groups. If this process fails, an error message is triggered.

Finally, it will attempt to move the AD computer object to the specified OU. 

Any errors that occur during the process will be captured and used to create a build process error. Once all commands have been processed, the AD commands completion string will be added to the device's build state and updated in the build ticket.

.PARAMETER buildInfo
This mandatory parameter contains details about the build process of a device such as its AssetID, Hostname, OU and groups.

.PARAMETER ADCommandsCompletedString
The string to be used to denote that AD commands have been completed. Defaults to the message from the 'adCompletedState' of the 'BuildStates' in the 'DeviceDeploymentDefaultConfig' if not explicitly provided.

.EXAMPLE
Invoke-DeviceADCommands -buildInfo $buildInfo -ADCommandsCompletedString "AD Commands Completed Successfully."

This example would attempt to add the device as described in the input object $buildInfo to the specified AD groups and move to the assigned OU. Then it updates the build ticket to indicate that the AD commands for the device have been completed successfully.

.INPUTS
PSCustomObject from Pipeline
The object should have properties: AssetID, Hostname, OU, Groups

.OUTPUTS 
Outputs build information string.
The function will output to the console if it successfully adds to the device groups, moves it to the correct OU and then updates the build ticket to include a message that AD commands have been completed.
#>

function Invoke-DeviceADCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		$ADCommandsCompletedString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message,

		[Parameter()]
		[ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
	)

	begin {
		$msg = ""
	}
	process {
		try {
			#get ad Comp
			try {
				$ADComp = Get-ADComputer -Identity $buildInfo.AssetID -Credential $Credential
			} catch {
				# if comp cant be found using asset id, try with hostname (lest rename fails)
				try {
					$ADComp = Get-ADComputer -Identity $buildInfo.hostname -Credential $Credential
				} catch {
					Write-Error "Computer with AssetID/Hostname $($buildInfo.AssetID)/$($buildInfo.hostname) doesn't exist in AD" -ErrorAction stop
				}
			}
	
			# add to groups
			foreach ($group in $buildInfo.groups) {
				Write-Verbose "Adding $($ADComp.SamAccountName) to $group"
				Add-ADGroupMember -Identity $group -Members $ADComp.SamAccountName -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Credential $Credential
			}
	
			# move to correct OU
			Write-Verbose "Moving $($ADComp.SamAccountName) to $($buildInfo.OU)"
			Move-ADObject -Identity $ADComp.DistinguishedName -TargetPath $buildInfo.OU -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference -Credential $Credential
	
		} catch {
			$msg = $DeviceDeploymentDefaultConfig.TicketInteraction.GeneralErrorMessage

			New-BuildProcessError -errorObj $_ -message "AD Commands have Failed. Please manually check that the device is in the listed OU and groups. This has not effected other parts of the build process." -functionName "Invoke-DeviceADCommands" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
		} finally {
			# add note to ticket that AD commands completed
			$buildInfo.buildState = $ADCommandsCompletedString
			Write-DeviceBuildTicket -buildInfo $buildInfo -message $msg
		}

	}
	end {
	}	
}