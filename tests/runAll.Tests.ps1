
#Dot source the files
Foreach ($test in (Get-ChildItem -Path $PSScriptRoot\*Tests.ps1  -Recurse -ErrorAction SilentlyContinue -Exclude runAll*)) {
	Try {
		$VerbosePreference = "SilentlyContinue"
		$debugPreference = "SilentlyContinue"
        . $test.fullname
        Write-Debug "Imported $($test.fullname)"
    } Catch {
        Write-Error -Message "Failed to test function $($test.fullname): $_"
    }
}