
Start-Transcript -path "C:\Intune_Setup\buildProcess\Logs\buildProcessV2.2\interactiveRun-$(Get-Date -format "ddMMyyyyhhmmss").log"

$DebugPreference = "SilentlyContinue"

Write-Verbose "BuildProcess Execution Started"

try {
	#------------------------------------------------- Setup -------------------------------------------------# 
	Import-Module TriCare-Common
	Import-Module TriCare-DeviceDeployment

	$config = Get-DeviceDeploymentDefaultConfig

	# run "Shift+F10" to bring GUI up
	& "$($config.Generic.BuildModulePath)\$($config.Generic.shiftF10RelativePath)"
	
	Update-AZConfig -EnableLoginByWam $false # this forces login with browser, should not be req

	Connect-KVUnattended | Out-Null

	# Check the device is in OOBE
	if (Test-OOBE -Verbose) {
		#-------------------------- Block Shutdowns until build process is completed --------------------------# 
		Block-DeviceShutdown -Verbose | Out-Null
		
		#------------------------ Get Build Data and Create Fresh Asset (if required) -------------------------# 
		$freshAsset = Register-DeviceWithFresh -Verbose
		$buildInfo = Get-DeviceBuildData -freshAsset $freshAsset -Verbose
		
		#----------------------------------- Set Ticket to Waiting on Build -----------------------------------# 
		Set-FreshTicketStatus -ticketID $buildInfo.ticketID -status $config.TicketInteraction.ticketWaitingOnBuildStatus

		#------------------------------------------ Check into Ticket -----------------------------------------# 
		#------------------------- (This invokes privilidged commands on serverside) --------------------------#
		$buildInfo.buildState = $config.TicketInteraction.BuildStates.checkInState.message # set state to "checked in"
		Write-DeviceBuildTicket -buildInfo $buildInfo -Verbose
		
		#------------------------------------------- Rename Device --------------------------------------------# 
		#----------------------- (needs to happen before device is moved to other OU) -------------------------#
		$buildInfo.buildState = $config.TicketInteraction.BuildStates.oldADCompRemovalPendingState.message
		Write-DeviceBuildTicket -buildInfo $buildInfo -Verbose

		# Wait for old ad object to be removed if it exists
		While (-not (Test-DeviceADDeviceRemovalCompletion -Verbose -buildInfo $buildInfo)) {
			Start-Sleep -Seconds 10
		}
		Set-DeviceName -AssetId $buildInfo.AssetID -Verbose

		$buildInfo.buildState = $config.TicketInteraction.BuildStates.adPendingState.message
		Write-DeviceBuildTicket -buildInfo $buildInfo -Verbose

		#------------------------------------ Set Generic Local Settings  -------------------------------------# 
		Set-DeviceLocalSettings -Verbose
		
		#----------------------------------------- Remove Bloatware  ------------------------------------------# 
		Remove-DeviceBloatware -Verbose

		#------------------------------------------ Update Software  ------------------------------------------# 
		# Initialize-DeviceWindowsUpdateEnviroment -Verbose
		# Update-DeviceWindowsUpdate -Verbose

		if (Test-DeviceDellCommandUpdate -Verbose) {
			Install-DeviceDellCommandUpdateDrivers -Verbose
			Invoke-DeviceDellCommandUpdateUpdates -Verbose
		}
		
		#------------------------------- Wait for AD Commands to Be Completed  --------------------------------# 
		While (-not (Test-DeviceADCommandCompletion -Verbose -buildInfo $buildInfo)) {
			Start-Sleep -Seconds 10
		}
		#----------------------------------- Sync Various Managment Systems -----------------------------------# 
		Invoke-GPUpdate -Verbose #does this want to wait until first login?
		Invoke-DeviceCompanyPortalSync -Verbose

		#---------------------------------------------- Mark as Completed -----------------------------------------------# 
		$buildInfo.buildState = $config.TicketInteraction.BuildStates.completedState.message
		Write-DeviceBuildTicket -buildInfo $buildInfo -Verbose
		Show-DeviceUserMessage -title "Build Completed" -message "Build Succesfully Completed. Please review build ticket and resolve any errors"

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

Stop-Transcript