
# Documentation
<#
.SYNOPSIS
This function removes a duplicate Active Directory (AD) device based on the AssetID provided in the buildInfo parameter.

.DESCRIPTION
The Remove-DeviceADDuplicate function attempts to remove a duplicate device from Active Directory based on an Asset ID.
If the device is found, it is removed. If it is not found, the function simply returns a verbose output stating the device does not exist in Active Directory.
Any errors during this process are caught and logged, with a recommendation to manually check Active Directory and remove any computers with the same Asset ID.
After the process completes, a note is added to the ticket that the AD removal commands have been completed.

.PARAMETER buildInfo
This parameter accepts pipeline input and is mandatory. It should contain the details about the build, including the AssetID of the device.

.PARAMETER ADDeviceRemovalCompletionString
This is an optional string parameter to mark the build state. If not provided, a default value from the DeviceDeploymentDefaultConfig is used.

.EXAMPLE
PS> Remove-DeviceADDuplicate -buildInfo $exampleBuildInfo
This command would attempt to remove a duplicate device from AD, based on the AssetID provided in the exampleBuildInfo object.

.EXAMPLE
PS> $exampleBuildInfo | Remove-DeviceADDuplicate
This command is the same as the first example, but the buildInfo object is provided through pipeline input.
#>


function Remove-DeviceADDuplicate {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory,ValueFromPipeline)]
		$buildInfo,

		[Parameter()]
		[string]$ADDeviceRemovalCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.oldADCompRemovalCompletedState.message,
		
		[Parameter()]
		[string]$pauseTime = $DeviceDeploymentDefaultConfig.ADCommands.replicationSeconds
	)

	begin {
		$msg = ""
	}
	process {
		try {
			#get ad Comp
			try {
				$ADComp = Get-ADComputer -Identity $buildInfo.AssetID -ErrorAction SilentlyContinue -Verbose:$VerbosePreference
			} catch {
				Write-Verbose "No device with name $($buildInfo.AssetID) exists in AD"
				return
			}

			$ADComp.Name | Remove-ADDevice -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
			Write-Verbose "Removed $($buildInfo.AssetID) from AD"

			#pause to allow time for deletion to replicate across DC's
			Write-Verbose "Waiting for $pauseTime seconds to allow changes to replicate"
			Start-Sleep -Seconds $pauseTime
		}
		catch {
			$msg = $DeviceDeploymentDefaultConfig.TicketInteraction.GeneralErrorMessage

			New-BuildProcessError -errorObj $_ -message "Rename Commands have Failed. To solve this, please manually check AD for any OLD AD-Computers with the same AssetID and remove them. Double check that you're not removing this device! Then manually rename the PC" -functionName "Remove-DeviceADDuplicate" -buildInfo $buildInfo -debugMode -ErrorAction "Continue"
			
		} finally {
			# add note to ticket that AD removal commands completed
			$buildInfo.buildState = $ADDeviceRemovalCompletionString
			Write-DeviceBuildTicket -buildInfo $buildInfo -message $msg -Verbose:$VerbosePreference
			Write-Verbose "Wrote to built ticket $($buildInfo | ConvertTo-Json)"
		}
		
	}
	end {
	}	
}