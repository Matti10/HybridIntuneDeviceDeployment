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

				return New-BuildInfoObj -AssetId $FreshAsset.Name -serialNumber $freshAsset.type_fields.(Get-FreshAssetTypeFieldName -field "serial" -freshAsset $freshAsset) -type $buildDetails.device_type_requested -build $buildDetails.hardware_use_build_type -freshLocation $buildDetails.facility[0] -ticketID $buildTicketID -freshAsset $freshAsset -OU $OU -groups $groups

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