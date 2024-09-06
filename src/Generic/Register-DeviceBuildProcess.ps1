
# Documentation
<#
.SYNOPSIS
This PowerShell function "Register-DeviceBuildProcess" is used to register a device build process, which includes creating a new item property on the given run path and runs a sequence of commands.

.DESCRIPTION
The function accepts three parameters, namely "runPath", "psExecPath", and "BuildProcessPath". The function starts by capturing any potential errors in an array. It then checks whether the process should proceed based on the current system settings.

If the condition is met, the function executes the "psExecPath" command with parameters to run a PowerShell session, and then creates a new item property in the Windows Registry at the specified "runPath". The new property "BuildProcess" is set with a value containing a string of commands that include importing two modules "TriCare-Common" and "TriCare-DeviceDeployment", and running a script at "BuildProcessPath".

In the case of any errors during execution, these are stored in the error list array and written to the error stream via the "Write-Error" cmdlet. The function concludes by checking if there are any errors stored and if so, writes them out.

.PARAMETER runPath
The registry path where a new property "BuildProcess" will be created.

.PARAMETER psExecPath
The file path to "psExec", which allows programs to be executed interactively on a remote system. 

.PARAMETER BuildProcessPath
The file path to the PowerShell script that contains the device build process. 

.EXAMPLE
Register-DeviceBuildProcess -runPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -psExecPath "C:\path\to\PsExec.exe" -BuildProcessPath "C:\path\to\myscript.ps1"
#>

function Register-DeviceBuildProcess {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # This parameter takes the registry path where a new item property will be created
        [Parameter()]
        [string]
        $runPath = $DeviceDeploymentDefaultConfig.Generic.RunRegistryPath,

        # This parameter is mandatory and denotes the path to PsExec
        [Parameter(Mandatory)]
        [string]
        $psExecPath,

        # This parameter is mandatory and denotes the path to the PowerShell script for the build process.
        [Parameter(Mandatory)]
        [string]
        $BuildProcessPath
    )

    # Beginning of the block, initializing an array to collect any potential errors during execution
    begin {
        $errorList = @()
    }

    process {
        # Check host
        if ($PSCmdlet.ShouldProcess("$(hostname)")) {
            try {
                # Run "psExecPath" command with parameters to open Powershell session
                & $psExecPath -i -s powershell "Read-Host"

                # Create new registry property named "BuildProcess" on the "runPath" with a value as string of commands
                New-ItemProperty -Path $runPath -Name "BuildProcess" -Value "$psExecPath -i -s powershell `"Import-Module TriCare-Common; Import-Module TriCare-DeviceDeployment; . '$BuildProcessPath'`""
            }
            # Catch block to capture any errors that might occur and add them to the error array
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }

    # At the end of the function check if any errors occurred and write them out
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }
}