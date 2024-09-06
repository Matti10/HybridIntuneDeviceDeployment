
<#
.SYNOPSIS
    Checks whether the AD command has been completed based on the ticket conversations in the build information.

.DESCRIPTION
    Test-DeviceADCommandCompletion is a PowerShell function that checks if the AD (Active Directory) command in ticket conversations within the build information object has been finished. If it has been completed the function returns true; 
    otherwise, it returns false.

.PARAMETER BuildInfo
    The build information object that includes the ticket ID and other relevant information.

.PARAMETER ADCommandCompletionString
    The AD (Active Directory) command completion string to search for in the ticket conversations.
    Defaults to the message defined in $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message.

.EXAMPLE
    $buildInfo = Get-BuildInfo -ID 12345
    Test-DeviceADCommandCompletion -BuildInfo $buildInfo

    This example gets the build information for the ID 12345 and checks the ticket conversations for the AD command completion string.

#>
function Test-DeviceADCommandCompletion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Object]$BuildInfo,
        
        [Parameter()]
        [string]$ADCommandCompletionString = $DeviceDeploymentDefaultConfig.TicketInteraction.BuildStates.adCompletedState.message
    )

    begin {
        # Initialize an empty array to store any errors that occur during the process
        $errorList = @()
    }
    process {
        try {
            # Check if the cmdlet should process the given build information
            if ($PSCmdlet.ShouldProcess("$($BuildInfo)")) {                
                #--------------------------- Get All notes for the ticket  ---------------------------# 
                # Retrieve all conversations for the given ticket ID
                $conversations = Get-FreshTicketConversations -ticketID $BuildInfo.ticketID
                
                # Loop through each conversation
                foreach ($conversation in $conversations) {
                    # Check if the conversation contains the AD command completion string and the build GUID
                    if ("$($conversation)" -like "*$ADCommandCompletionString*$($BuildInfo.GUID)*") {
                        # If found, return true
                        return $true
                    }
                }
                
                # If not found, return false
                return $false
            }
        }
        catch {
            # If an error occurs, add it to the error list and write the error
            $errorList += $_
            Write-Error $_
        }
    }
    end {
        # If there are any errors, write a comprehensive error message and stop the script
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }    
}