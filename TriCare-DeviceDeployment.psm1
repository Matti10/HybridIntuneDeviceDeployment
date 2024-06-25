# TriCare Common Library for PowerShell scripts

#Get public and private function definition files.
Set-StrictMode -Version 2.0


<#---------------------- Common Defines ----------------------#>
$DeviceDeploymentDefaultConfig = Get-Content -Path "$PSScriptRoot\src\defaultConfig.json" | ConvertFrom-Json

Connect-TriCareMgGraph

<#---------------------- Include Functions ----------------------#>
Foreach ($import in (Get-ChildItem -Path $PSScriptRoot\src\*.ps1  -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.FullName -notlike"*Driver Scripts*"})) {
    Try {
        . $import.fullname
        Write-Debug "Imported $($import.fullname)"
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

<#------------------------------------------------------------#>

# This is the difference between instantaneous downloads and timeouts.
# Why?  Who knows, but I wasted a week trying to resolve a problem with eCase timing out when run from Task Scheduler.
# Adding this line solved the problem.
# https://stackoverflow.com/questions/28682642/powershell-why-is-using-invoke-webrequest-much-slower-than-a-browser-download
$ProgressPreference = 'SilentlyContinue'

