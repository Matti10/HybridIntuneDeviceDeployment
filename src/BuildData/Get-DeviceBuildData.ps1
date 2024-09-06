
<#
.SYNOPSIS
Retrieves the device build data for a specified asset.

.DESCRIPTION
This function gets the device build data of a given asset. It handles user messaging over multiple attempts to fetch the build tickets. 
It sorts the build tickets by their last updated time and uses the latest one to get the build details.
Later, it fetches the Organizational Unit and Groups from Correlation and the Intune ID for the device. 
In case of any errors while processing the function, it collects them and throws them at the end of the function execution.

.PARAMETER freshAsset
A mandatory parameter that carries the asset data to get its build data. 

.PARAMETER messageTemplates
An optional parameter that stores the different messages to show to the user during 1st and subsequent attempts to get the device build data.

.EXAMPLE
Get-DeviceBuildData -freshAsset $asset -messageTemplates $messages

.INPUTS
FreshAsset: A PSDriveInfo object containing details of the device.
MessageTemplates: A hashtable containing templates of different user messages.

.OUTPUTS
Returns an object containing the below properties:

AssetId: The ID of the device.
serialNumber: The serial number of the device.
type: The type of the device.
build: The build type of the device.
freshLocation: The facility location of the device.
ticketID: The ID of the ticket related to the device's build.
freshAsset: The fresh asset object containing detailed information about the device.
OU: The Organizational Unit related to the device.
groups: The groups which the device is part of.
intuneID: The Intune ID of the device.

.NOTES
This function relies on the Freshservice API to get asset data.
It can handle user interaction for messaging during the multiple attempts to fetch build tickets.
#>
function Get-DeviceBuildData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline,Mandatory)]
		$freshAsset,

		[Parameter()]
		$messageTemplates = $DeviceDeploymentDefaultConfig.DeviceUserInteraction.Messages
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($freshAsset.Name)) {
			try {
				$attemptCount = 0
				do {
					#manage user messaging
					if ($attemptCount -eq 1) {
						Show-DeviceUserMessage -message $messageTemplates.buildTicketAssignmentFirstAttempt.message -title $messageTemplates.buildTicketAssignmentFirstAttempt.title -wait -messageBoxConfigCode $messageTemplates.buildTicketAssignmentFirstAttempt.messageBoxConfiguration -placeholderValue $freshAsset.Name
					} elseif ($attemptCount -gt 1) {
						Show-DeviceUserMessage -message $messageTemplates.buildTicketAssignmentOtherAttempts.message -title $messageTemplates.buildTicketAssignmentOtherAttempts.title -wait -messageBoxConfigCode $messageTemplates.buildTicketAssignmentOtherAttempts.messageBoxConfiguration -placeholderValue $freshAsset.Name
					}

					$buildTickets = $freshAsset | Get-FreshAssetsTickets -ErrorAction SilentlyContinue
				
					# filter non build tickets out
					try {
						$buildTickets = $buildTickets | Where-Object {
							foreach ($pattern in $DeviceDeploymentDefaultConfig.Deployment.buildTicketNamePatterns) {
								if ($_.request_details -like $pattern) {
									return $true
								}
							}
							return $false
						}
					}
					catch [System.Management.Automation.PropertyNotFoundException] {
						Write-Verbose "Device has no build tickets"
					}
					
					$attemptCount++ #increment attemptCount
				} while ($null -eq $buildTickets)

				#get the newest ticket
				$buildTicketID = ($buildTickets | Sort-Object -Property updated_at -Descending)[0]."request_id".split("-")[1] # request id has a prefix "SR-"/"INC-" 

				$buildDetails = (Get-FreshTicketsRequestedItems -ticketID $buildTicketID).custom_fields

				# Get OU and Groups from Correlation
				$corrInfo = Find-DeviceCorrelationInfo -build $buildDetails.hardware_use_build_type -facility $buildDetails.facility[0]

				$groups = Get-DeviceBuildGroups -build $corrInfo.buildCorrelation -facility $corrInfo.facilityCorrelation
				$OU = Get-DeviceBuildOU -build $corrInfo.buildCorrelation -facility $corrInfo.facilityCorrelation

				$intuneID = Get-DeviceIntuneID

				return New-BuildInfoObj -AssetId $FreshAsset.Name -serialNumber $freshAsset.type_fields.(Get-FreshAssetTypeFieldName -field "serial" -freshAsset $freshAsset) -type $buildDetails.device_type_requested -build $buildDetails.hardware_use_build_type -freshLocation $buildDetails.facility[0] -ticketID $buildTicketID -freshAsset $freshAsset -OU $OU -groups $groups -intuneID $intuneID

			}
			catch {
				$errorList += $_
				Write-Error $_
			}
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}