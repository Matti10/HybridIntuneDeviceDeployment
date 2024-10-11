
function Invoke-BuildProcessRetry {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # Specifies the modules that should be imported.
        [Parameter()]
		[string]
        $message = ""
    )

    # Begin block of function: Initialize an empty array to contain all errors.
    begin {
        $errorList = @()
    }

    # Process block of function: Iterate over each module and attempt to import it.
    process {
        if ($PSCmdlet.ShouldProcess("")) {
            try {
                $result = Show-DeviceUserMessage -message $messageTemplates.buildTicketAssignmentFirstAttempt.message -title $messageTemplates.buildTicketAssignmentFirstAttempt.title -wait -messageBoxConfigCode $messageTemplates.buildTicketAssignmentFirstAttempt.messageBoxConfiguration -placeholderValue $freshAsset.Name
            }
            catch {
                $errorList += $_ # Collects encountered error in this block.
                Write-Error $_ # Writes out caught error.
            }
        }
    }

    # End block of function: Notify of any import errors that occurred during process.
    end {
        if ($errorList.count -ne 0) {
            # Outputs an error message detailing all import errors that occurred during execution.
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }
}