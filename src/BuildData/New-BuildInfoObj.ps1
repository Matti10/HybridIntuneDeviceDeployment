
# Documentation
<#
.SYNOPSIS
New-BuildInfoObj is a PowerShell function to create a custom object with details about a particular build process.

.DESCRIPTION
The New-BuildInfoObj function creates a PowerShell custom object (PSCustomObject) that contains properties related to asset information, hostname, type, serial number, build, organizational unit, group, ticket ID, build state, GUID, and Intune ID. 

.PARAMETER AssetID 
The ID of the Asset, this parameter is mandatory.

.PARAMETER hostname 
Indicates the hostname of the server. If no value is provided, the default system hostname will be used.

.PARAMETER serialNumber 
Optional parameter. It represents the serial number of the device.

.PARAMETER type 
This mandatory parameter specifies the server type.

.PARAMETER build 
This mandatory parameter represents the build version.

.PARAMETER OU 
A Mandatory parameter which reflects the Organisational Unit.

.PARAMETER groups 
An array parameter that requires one or more group names this device belongs to.

.PARAMETER ticketID 
A string that represents the ticket ID associated with the build, this parameter is Mandatory.

.PARAMETER freshAsset 
A mandatory parameter which reflects if the asset is new or not.

.PARAMETER GUID
Optional parameter for the GUID. If not specified, it will be generated using the serial number and current date and time in FileTimeUtc() format.

.PARAMETER freshLocation 
An optional parameter that specifies the location of the fresh asset.

.PARAMETER buildState 
An optional parameter for the build state. If not provided, the initial build state message from the DeviceDeploymentDefaultConfig will be used.

.PARAMETER IntuneID 
Optional parameter for the IntuneID.

.EXAMPLE
$buildInfo = New-BuildInfoObj -AssetID "123" -type "Server" -build "1.0.0" -ticketID "tick123" -freshAsset $true -OU "IT" -groups "Group1", "Group2"

This example creates a build information object for an asset with ID 123, type 'Server', build '1.0.0', ticket ID 'tick123', freshAsset $true, OU 'IT', and is a member of 'Group1' and 'Group2'.

.INPUTS
You can pipe a string to New-BuildInfoObj.

.OUTPUTS
New-BuildInfoObj outputs a PSCustomObject with properties for AssetID, hostname, serialNumber, type, build, OU, groups, ticketID, buildState, GUID, freshAsset, freshLocation, and IntuneID.


#>

function New-BuildInfoObj {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory)]
		[string]$AssetID,

		[Parameter()]
		[string]$hostname = "$(hostname)",

		[Parameter()]
		[string]$serialNumber = "",

		[Parameter(Mandatory)]
		[string]$type,

		[Parameter(Mandatory)]
		[string]$build,

		[Parameter(Mandatory)]
		[string]$ticketID,

		[Parameter(Mandatory)]
		$freshAsset,

		[Parameter()]
		$GUID = "",

		[Parameter(Mandatory)]
		[string]$OU = "",

		[Parameter(Mandatory)]
		[string[]]$groups,

		[Parameter()]
		[string]$freshLocation = "",

		[Parameter()]
		[string]$buildState = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.initialState.message,

		[Parameter()]
		[string]$IntuneID = ""
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess($AssetID)) {
			try {
				if ("" -eq $GUID) {
					$GUID = "$($serialNumber)-$((Get-Date).ToFileTimeUtc())"
				}
				
				return [PSCustomObject]@{
					AssetID      = $AssetID
					Hostname     = $hostname
					serialNumber = $serialNumber
					type         = $type
					build        = $build
					OU           = $OU
					groups       = $groups
					ticketID     = $ticketID
					buildState   = $buildState
					GUID         = $GUID
					freshAsset   = $freshAsset
					IntuneID     = $IntuneID
				}
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