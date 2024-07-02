
$DebugPreference = "SilentlyContinue"
$VerbosePreference = "Continue"

Write-Verbose "BuildProcess Execution Started"

try {
	#--------------------------- Setup ---------------------------# 
	$config = Get-DeviceDeploymentDefaultConfig
	Update-AZConfig -EnableLoginByWam $false # this forces login with browser, should not be req

	# Check the device is in OOBE
	if (Test-OOBE -whatif) {
		#-------------------------- Block Shutdowns until build process is completed --------------------------# 
		Block-DeviceShutdown -Verbose:$VerbosePreference | Out-Null


		#------------------------ Get Build Data and Create Fresh Asset (if required)  ------------------------# 
		$freshAsset = Register-DeviceWithFresh -Verbose:$VerbosePreference
		$buildData = Get-DeviceBuildData -freshAsset $freshAsset -Verbose:$VerbosePreference

		#------------------------------------------- Rename Device --------------------------------------------# 
		#----------------------- (needs to happen before device is moved to other OU) -------------------------#
		Set-DeviceName -AssetId $buildData.AssetID -Verbose:$VerbosePreference

		#------------------------------------------ Check into Ticket -----------------------------------------# 
		#------------------------- (This invokes privilidged commands on serverside) --------------------------#
		$buildData.buildState = $config.TicketInteraction.BuildStates.checkInState.message # set state to "checked in"
		Write-DeviceBuildTicket -buildInfo $buildData -Verbose:$VerbosePreference

		#------------------------------------ Set Generic Local Settings  -------------------------------------# 
		Set-DeviceLocalSettings -Verbose:$VerbosePreference
		
		#----------------------------------------- Remove Bloatware  ------------------------------------------# 
		Remove-DeviceBloatware -Verbose:$VerbosePreference

		#------------------------------------------ Update Software  ------------------------------------------# 
		Initialize-DeviceWindowsUpdateEnviroment -Verbose:$VerbosePreference
		Update-DeviceWindowsUpdate -Verbose:$VerbosePreference

		if (Test-DeviceDellCommandUpdate -Verbose:$VerbosePreference) {
			Install-DeviceDellCommandUpdateDrivers -Verbose:$VerbosePreference
			Invoke-DeviceDellCommandUpdateUpdates -Verbose:$VerbosePreference
		}
		
		#------------------------------- Wait for AD Commands to Be Completed  --------------------------------# 
		While (-not (Test-DeviceADCommandCompletion -Verbose:$VerbosePreference)) {
			Start-Sleep -Seconds 10
		}
		#----------------------------------- Sync Various Managment Systems -----------------------------------# 
		Invoke-GPUpdate -Verbose:$VerbosePreference #does this want to wait until first login?
		Invoke-DeviceCompanyPortalSync -Verbose:$VerbosePreference


		#---------------------------------------------- Cleanup -----------------------------------------------# 
		# Invoke-DeviceDeploymentCleanupCommands #should probably do this after first login
	}
}
catch {
	$_
	##TODO Write a function to handle errors whether we have fresh connection or not

		#---------------------------------------------- Cleanup -----------------------------------------------# 
		# Invoke-DeviceDeploymentCleanupCommands
}