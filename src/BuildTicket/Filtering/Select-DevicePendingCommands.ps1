
<#
.SYNOPSIS
The Select-DevicePendingCommands function assists in identifying pending commands from build ticket conversations containing a given string. Furthermore, if the string indicating command completion is found in the conversations, it means prior pending commands have been executed and there are no pending commands. 

.PARAMETER -buildTicketData 
(System.Object)
The data derived from the build ticket. This parameter must contain two properties: �buildInfo� and 'conversations'.

.PARAMETER -commandsPendingString 
(string)
A string that tags pending commands in a conversation.

.PARAMETER -commandsCompleteString 
(string)
A string that tags executed commands in a conversation.

.PARAMETER COMMON PARAMETERS
This cmdlet supports the common parameters: Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, and OutVariable.

.DESCRIPTION
The function Select-DevicePendingCommands delegates a task that sets a flag based on strings found in the conversations linked with a build ticket. The function makes the most of pipeline processing to manage multiple inputs. 

It goes through each conversation tagged with a build's GUID, checking if the build notes contain the `commandsPendingString` and/or the `commandsCompleteString`. 

In case the function identifies a note with the complete string, the flag is unset (pending is set to $false) and the function concludes, skipping any pending commands that precede it in the conversation. However, if it detects the `commandsPendingString`, the flag is set (pending is set to $true); subsequent notes are ordinarily scanned till it detects the `commandsCompleteString` or it goes through all of them. 

If at the end of scanning all the notes, it identifies that the pending flag is set, it returns the buildInfo. If any exception is encountered in the process, it feeds that error into an error list and write those errors to the error output stream. 

.INPUTS
System.Object: This function takes an object input that comprises two properties: 'buildInfo' and 'conversations'.

.OUTPUTS
System.Object: If there are pending commands, the function returns the 'buildInfo'. If there is no pending command, it does not return anything.

.EXAMPLE

### Example 1


$buildData = Get-BuildTicketData -TicketID '123456'
Select-DevicePendingCommands -buildTicketData $buildData -commandsPendingString "commands_pending" -commandsCompleteString "commands_complete"


In this example, the `Get-BuildTicketData` function is utilized to fetch the build ticket data for a ticket with ID '123456'. These data act as the input for the `Select-DevicePendingCommands` function, alongside the `commandsPendingString` and `commandsCompleteString`, which are set to "commands_pending" and "commands_complete" respectively.


.NOTES
The function should be utilized with appropriate error handling in the PowerShell script, given that it triggers out errors whenever exceptions are encountered.

#>
function Select-DevicePendingCommands {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[System.Object]$buildTicketData,
		
		[Parameter(Mandatory)]
		[string]$commandsPendingString,

		[Parameter(Mandatory)]
		[string]$commandsCompleteString
	)

	begin {
		$errorList = @()
	}
	process {
		try {
			$buildInfo = $buildTicketData.buildInfo
			$conversations = $buildTicketData.conversations

			$pending = $false
			
			$buildNotes = $conversations | Where-Object {$_.body -like "*$($buildInfo.GUID)*"}
			foreach ($buildNote in $buildNotes) {
				if ($buildNote.body -like "*$commandsCompleteString*") {
					# commands already completed
					$pending = $false
					return
				}

				if ($buildNote.body -like "*$commandsPendingString*") {
					$pending = $true
				}

			}

			if ($pending) {
				return $buildInfo
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