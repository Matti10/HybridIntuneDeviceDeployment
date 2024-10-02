
Start-Transcript -path "C:\Intune_Setup\buildProcess\Logs\buildProcessV2.4\interactiveRun-$(Get-Date -format "ddMMyyyyhhmmss").log"

$DebugPreference = "SilentlyContinue"

Write-Verbose "BuildProcess Execution Started"

try {
	#------------------------------------------------- Setup -------------------------------------------------# 
	Import-Module TriCare-Common
	Import-Module TriCare-DeviceDeployment

	$config = Get-DeviceDeploymentDefaultConfig
	
	# Check the device is in OOBE
	if (Test-OOBE -Verbose) {	
		# run "Shift+F10" to bring GUI up
		& "$($config.Generic.BuildModulePath)\$($config.Generic.shiftF10RelativePath)"
	}	
	Update-AZConfig -EnableLoginByWam $false # this forces login with browser, should not be req

	Connect-KVUnattended | Out-Null
	#-------------------------- Block Shutdowns until build process is completed --------------------------# 
	Block-DeviceShutdown -Verbose | Out-Null
	
	#------------------------ Get Build Data and Create Fresh Asset (if required) -------------------------#
	try {
		$freshAsset = Register-DeviceWithFresh -Verbose
		$buildInfo = Get-DeviceBuildData -freshAsset $freshAsset -Verbose
	} catch {
		New-BuildProcessError -errorObj $_ -message "Unable to Retrive Build Info from Fresh. This without this info the process cannot contine. Please check device exists in fresh and is setup as per build documentation. Then wipe the device and restart" -functionName "Device Registration with Fresh" -popup -ErrorAction "Stop"
	}
	
	#----------------------------------- Set Ticket to Waiting on Build -----------------------------------# 
	Set-FreshTicketStatus -ticketID $buildInfo.ticketID -status $config.TicketInteraction.ticketWaitingOnBuildStatus -overwriteDescription

	#------------------------------------------ Check into Ticket -----------------------------------------# 
	#------------------------- (This invokes privilidged commands on serverside) --------------------------#
	$buildInfo.buildState = $config.TicketInteraction.BuildStates.checkInState.message # set state to "checked in"
	Write-DeviceBuildStatus -buildInfo $buildInfo -Verbose
	
	#------------------------------------------- Rename Device --------------------------------------------# 
	#----------------------- (needs to happen before device is moved to other OU) -------------------------#
	$buildInfo.buildState = $config.TicketInteraction.BuildStates.oldADCompRemovalPendingState.message
	Write-DeviceBuildStatus -buildInfo $buildInfo -Verbose

	# Wait for old ad object to be removed if it exists
	While (-not (Test-DeviceADDeviceRemovalCompletion -Verbose -buildInfo $buildInfo)) {
		Start-Sleep -Seconds 10
	}
	Set-DeviceName -buildInfo $buildInfo -Verbose

	$buildInfo.buildState = $config.TicketInteraction.BuildStates.adPendingState.message
	Write-DeviceBuildStatus -buildInfo $buildInfo -Verbose

	#------------------------------------ Set Generic Local Settings  -------------------------------------# 
	Set-DeviceLocalSettings -Verbose -buildInfo $buildInfo
	
	#----------------------------------------- Remove Bloatware  ------------------------------------------# 
	Remove-DeviceBloatware -Verbose -buildInfo $buildInfo

	#------------------------------------------ Update Software  ------------------------------------------# 
	# Initialize-DeviceWindowsUpdateEnviroment -Verbose
	# Update-DeviceWindowsUpdate -Verbose

	if (Test-DeviceDellCommandUpdate -Verbose) {
		Install-DeviceDellCommandUpdateDrivers -Verbose -buildInfo $buildInfo
		Invoke-DeviceDellCommandUpdateUpdates -Verbose -buildInfo $buildInfo
	}
	
	#------------------------------- Wait for AD Commands to Be Completed  --------------------------------# 
	While (-not (Test-DeviceADCommandCompletion -Verbose -buildInfo $buildInfo)) {
		Start-Sleep -Seconds 10
	}
	#----------------------------------- Sync Various Managment Systems -----------------------------------# 
	Invoke-GPUpdate -Verbose #does this want to wait until first login?
	Invoke-DeviceCompanyPortalSync -Verbose -buildInfo $buildInfo

	#---------------------------------------------- Mark as Completed -----------------------------------------------# 
	$buildInfo.buildState = $config.TicketInteraction.BuildStates.completedState.message
	Write-DeviceBuildStatus -buildInfo $buildInfo -Verbose
	Show-DeviceUserMessage -title "Build Completed" -message "Build Succesfully Completed. Please review build ticket and resolve any errors"

	#---------------------------------------------- Cleanup -----------------------------------------------# 
	# Invoke-DeviceDeploymentCleanupCommands #should probably do this after first login
	
}
catch {
	New-BuildProcessError -errorObj $_ -message "There has been an error in the build process, please see the below output:`n$_" -functionName "Build Process Main" -popup -ErrorAction "Stop" -buildInfo $buildInfo

		#---------------------------------------------- Cleanup -----------------------------------------------# 
		# Invoke-DeviceDeploymentCleanupCommands
}

Stop-Transcript