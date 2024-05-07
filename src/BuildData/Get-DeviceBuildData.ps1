function Get-DeviceBuildData {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline)]
		[string]$identity = "",

		[Parameter()]
		[string]$serialNumber = "",

		[Parameter(Mandatory)]
		[string]$API_Key
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($identity)) {
			try {
				#get devices tickets
				if ($serialNumber -ne "") {
					$buildTickets = Get-FreshAssetsTickets -API_Key $API_Key -serialNum $serialNumber -ErrorAction SilentlyContinue
					$identity = (Get-FreshAsset -API_Key $API_Key -serialNum $serialNumber -ErrorAction SilentlyContinue).name
				}
				elseif ($identity -ne "") {
					$buildTickets = Get-FreshAssetsTickets -API_Key $API_Key -name $identity -ErrorAction SilentlyContinue
				}
				else {
					#input validations
					Write-Error -Message "Identity and Serial Number paramaters are null, please provide a value" -ErrorAction Stop
				}

				# filter non build tickets out
				try {
					$buildTickets = $buildTickets
					| Where-Object {
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

				if ($null -eq $buildTickets) {
					Write-Error "$identity has no built tickets associated with it"
					return $null
				}


				#get the newest ticket
				$buildTicketID = ($buildTickets | Sort-Object -Property updated_at -Descending)[0]."request_id".split("-")[1] # request id has a prefix "SR-"/"INC-" 

				$buildDetails = (Get-FreshTicketsRequestedItems -API_Key $API_Key -ticketID $buildTicketID).custom_fields

				return New-BuildInfoObj -AssetId $identity -serialNumber $serialNumber -type $buildDetails.device_type_requested -build $buildDetails.hardware_use_build_type -freshLocation $buildDetails.facility[0] -ticketID $buildTicketID

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