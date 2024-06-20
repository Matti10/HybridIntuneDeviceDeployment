Write-Debug "BuildProcess Execution Started"

try {
	#--------------------------- Setup ---------------------------# 
	$config = Get-DeviceDeploymentDefaultConfig
	
	# Check the device is in OOBE
	if (Test-OOBE -whatif) {
		$API_Key = Get-KVSecret -KeyVault $config.Security.KeyVaultName -Secret $config.Security.FreshAPIKey_KeyVaultKey

		#--------------------------- Block Shutdowns until build process is completed ---------------------------# 
		Block-DeviceShutdown

		#--------------------------- Get Build Data and Create Fresh Asset (if required)  ---------------------------# 
		$freshAsset = Register-DeviceWithFresh -API_Key $API_Key
		$buildData = Get-DeviceBuildData -freshAsset $freshAsset -API_Key $API_Key

		#--------------------------- Rename Device ---------------------------# 
		#------- (needs to happen before device is moved to other OU) --------#
		Set-DeviceName -AssetId $buildData.AssetID

		#--------------------------- Check into Ticket ---------------------------# 
		#----------- (This invokes privilidged commands on serverside) -----------#
		$buildData.buildState = $config.TicketInteraction.BuildStates.checkInState.message # set state to "checked in"
		Write-DeviceBuildTicket -buildInfo $buildData

		#--------------------------- Set Generic Local Settings  ---------------------------# 
		Set-DeviceLocalSettings
		
		#--------------------------- Remove Bloatware  ---------------------------# 
		Remove-DeviceBloatware

		#--------------------------- Update Software  ---------------------------# 
		Initialize-DeviceWindowsUpdateEnviroment
		Initialize-DeviceWindowsUpdate

		if (Test-DeviceDellCommandUpdate) {
			Install-DeviceDellCommandUpdateDrivers
			Invoke-DeviceDellCommandUpdateUpdates
		}
		
		#--------------------------- Wait for AD Commands to Be Completed  ---------------------------# 
		While (-not (Test-DeviceADCommandCompletion)) {
			Start-Sleep -Seconds 10
		}
		#--------------------------- Sync Various Managment Systems ---------------------------# 
		Invoke-GPUpdate #does this want to wait until first login?
		Invoke-DeviceCompanyPortalSync


		#--------------------------- Cleanup ---------------------------# 
		Invoke-DeviceDeploymentCleanupCommands
	}
}
catch {
	$_
	##TODO Write a function to handle errors whether we have fresh connection or not

		#--------------------------- Cleanup ---------------------------# 
		Invoke-DeviceDeploymentCleanupCommands
}





