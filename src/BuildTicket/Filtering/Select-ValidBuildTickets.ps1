
<# Documentation
# PowerShell Function: Select-ValidBuildTickets

This function, `Select-ValidBuildTickets`, is designed to allow for the selection of valid build tickets by filtering tickets based on the title patterns specified. It supports pipeline input, follows the standard begin/process/end structure of PowerShell advanced functions, and is capable of handling errors.

## Parameters

This function accepts two parameters:
- `$tickets` - Individual or array of ticket objects. This parameter accepts pipeline input.
- `$buildTicketTitlePatterns` - An array of string patterns to filter the tickets by their subjects. By default, it uses the `buildticketTitlePatterns` from `DeviceDeploymentDefaultConfig.TicketInteraction` available within the current session context.

## Function Execution Flow

### `begin` Block

In the `begin` block, an empty error list array `$errorList` is created to capture any errors that may occur during the execution.

### `process` Block

In the `process` block, it checks to see if `$PSCmdlet.ShouldProcess("")` is true. This is used in conjunction with the SupportsShouldProcess flag of CmdletBinding. If it is true, the script attempts to process the tickets. Validating whether `$tickets` is not null, the function iterates across `$buildTicketTitlePatterns`. When the subject of the `$tickets` matches the pattern, it returns the corresponding `$tickets`.

Errors are catched, added to `$errorList` and then written to the console (standard error).

### `end` Block

In the `end` block, it checks whether `$errorList.count` is not equal to zero, meaning there are errors captured in the list. If true, it writes an accumulated error message to the console and stops further execution. It also provides the call stack information using `Get-PSCallStack`, which can be useful for debugging purposes.

## Comment Based Help

As a best practice, every advanced function should have a comment-based help, formatted like below:


<#
.SYNOPSIS
Selects valid build tickets based on provided title patterns.

.DESCRIPTION
This function iterates over input tickets and if the ticket subject matches any of given patterns in buildTicketTitlePatterns parameter, returns them as valid tickets.

.PARAMETER tickets
The tickets to validate. Accepts pipeline input. 

.PARAMETER buildTicketTitlePatterns
An array of string patterns which are used to validate if ticket's subject matches any of them. Default value is taken from DeviceDeploymentDefaultConfig buildticketTitlePatterns.

.EXAMPLE
$titles = @('*build*', '*release*')
$tickets | Select-ValidBuildTickets -buildTicketTitlePatterns $titles

.INPUTS
System.String

.OUTPUTS
System.String
#>

function Select-ValidBuildTickets {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(ValueFromPipeline)]
		$tickets,

		[Parameter()]
		[string[]]
		$buildTicketTitlePatterns = $DeviceDeploymentDefaultConfig.TicketInteraction.buildticketTitlePatterns
	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess("")) {
			try {

				if ($null -ne $tickets) {
					foreach ($pattern in $buildTicketTitlePatterns) {
						if ($tickets.subject -like $pattern) {
							return $tickets
						}
					}
				}
			} catch {
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
