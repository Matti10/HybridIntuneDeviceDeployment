
<#
.SYNOPSIS
This function writes to a build ticket in fresh based on the information it receives.

.DESCRIPTION
Write-DeviceBuildTicket is a function that creates a new converstation in a build ticket during device deployment, based on the parameters received from the pipeline. Before creating the converstation, it processes the received parameters to ensure they're in a suitable format for the ticket. Any errors are captured and written to the errorList. 

BEGIN
At the beginning of function execution, an string array $errorList is initialized for storing errors encountered during execution.

PROCESS
During the processing block, data manipulation operations are performed to make the input data fit for ticket generation. Errors encountered during processing are caught and added to the errorList.

END
At the end of function execution, if there are any errors in the errorList, those are written out to the error stream.

.PARAMETER record  
This (mandatory) parameter takes a [System.Object] type input and gets its value from the pipeline. The record object contains all the information about the device build that is used as input for the ticket.

.PARAMETER message  
This parameter takes a [string] type input. It specifies the message text that is to be included in the ticket content.

.PARAMETER content  
This parameter takes a [string] type value. While the default content used is from DeviceDeploymentDefaultConfig.TicketInteraction.messageTemplate, this argument allows the user to override the default content.

.PARAMETER dateFormat  
This parameter provides a date format to be used. The default value for this parameter is DeviceDeploymentDefaultConfig.Generic.DefaultDateFormat.

.PARAMETER buildStates  
This parameter is used for matching build states from the DeviceDeploymentDefaultConfig object's TicketInteraction.BuildStates property.

.PARAMETER formattingConfig  
This parameter allows the user to specify the configuration for formatting the content. By default, the method uses the formatting configuration from DeviceDeploymentDefaultConfig.TicketInteraction.freshFormatting.

.PARAMETER listDisplayDelimiter  
This parameter takes a character string used as a delimiter when displaying lists. The default delimiter is taken from DeviceDeploymentDefaultConfig.TicketInteraction.listDisplayDelimiter.

.OUTPUTS
If the function executes successfully without any errors, it returns nothing. If the ShouldProcess parameter is false, the function returns the content. If the function execution throws an error, it returns an error message with the details of the error. It uses Write-Error to write out the error details to the error stream.

.NOTES
CmdletBinding is used to allow this function to support common Windows PowerShell function parameters such as -Verbose and -ShouldProcess.

This function requires the presence of other functions and objects like New-FreshTicketNote, ConvertTo-HtmlTable and DeviceDeploymentDefaultConfig for its execution. These are assumed to be available in the calling context.

.EXAMPLE
To use the function, you can do something like:

$record | Write-DeviceBuildTicket -message "This is a test message"

This command will use the given message and data from $record to write to the build ticket. 

#>
function Write-DeviceBuildQueue {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$BuildInfo,

		[Parameter()]
		$buildStates = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates,
		
		[Parameter()]
		$customObjectID = $DeviceDeploymentDefaultConfig.BuildQueue.CustomObjectID,
		
		[Parameter()]
		$listDisplayDelimiter = $DeviceDeploymentDefaultConfig.TicketInteraction.listDisplayDelimiter
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$record = [PSCustomObject]@{}
			#copy values into a temp object (BECAUSE POWERSHELL CANT NOT PASS BY REFERENCE!!!!!!!!)
			$BuildInfo | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} | ForEach-Object {
				$record | Add-Member -MemberType NoteProperty -Name $_.Name -Value $BuildInfo."$($_.Name)"
			}
			# change fresh asset object to its asset id
			try {
				$record.freshAsset = "$($record.freshAsset.display_ID)"
			} catch {
				#do nothing - the fresh asset feild is already the fresh asset tag (rather than a fresh asset object)
			}

			# represent list of groups as a string
			$tempGroups = $record.groups
			$record.groups = ""
			foreach ($group in $tempGroups) {
				$record.groups += "$group$listDisplayDelimiter$($record.groups)"
			}
			$record.groups = $record.groups.TrimEnd($listDisplayDelimiter)

			if (Test-DeviceCheckIn -buildInfo $BuildInfo) {
				
			} else {
				if ($PSCmdlet.ShouldProcess("CustomObjectID: $($record.recordID) State: $($buildInfo.buildState)")) {
					$result = New-FreshCustomObjectRecord -record $record -objectID $customObjectID
					$BuildInfo.RecordID = $result.bo_display_id
					return $BuildInfo
				} else {
					return $record
				}
			}
		}
		catch {
			$errorList += $_
			Write-Error $_
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}