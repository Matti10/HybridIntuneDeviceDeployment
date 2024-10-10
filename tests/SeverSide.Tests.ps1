BeforeAll {

    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force
		Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceManagment\TriCare-DeviceManagment.psm1" -Force
    } else {
		Import-Module TriCare-Common | Out-Null
		Import-Module .\TriCare-DeviceDeployment | Out-Null
		Import-Module .\TriCare-DeviceManagment | Out-Null
    }

	Set-FreshAPIKey -API_Key (Unprotect-String -encryptedString "AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAzAHtRA5HSkKHYFaSWBLfagAAAAACAAAAAAADZgAAwAAAABAAAAAC/qYwxhMfoyxy5QRmZbQXAAAAAASAAACgAAAAEAAAAPl+NPlquKeV/rY0/dxPL54YAAAApGYk+XDDktyVSHA0822U36GsRkAEta95FAAAACVrQYzGoe75lD1B8IX9Lf9SK0ub")

}
BeforeDiscovery {
	Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"		
	
	Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"

	Set-FreshAPIKey -API_Key (Unprotect-String -encryptedString "AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAzAHtRA5HSkKHYFaSWBLfagAAAAACAAAAAAADZgAAwAAAABAAAAAC/qYwxhMfoyxy5QRmZbQXAAAAAASAAACgAAAAEAAAAPl+NPlquKeV/rY0/dxPL54YAAAApGYk+XDDktyVSHA0822U36GsRkAEta95FAAAACVrQYzGoe75lD1B8IX9Lf9SK0ub")
}

Describe "Getting Data from Fresh" {
    Context "Testing if devices have checked in" {
		It "returns valid build GUID when check in is valid" {
			$result = Test-DeviceTicketCheckIn -conversations (Get-FreshTicketConversations -ticketID 101629) 
			$result.GUID | Should -not -be "99VVK63-133640215375952942"
			$result.GUID | Should -BeLike "*99VVK63-*"
		}

		It "returns false when device hasnt checked in" {
			Test-DeviceTicketCheckIn -conversations (Get-FreshTicketConversations -ticketID 101631) | Should -BeFalse
		}
	}
}


Describe "AD Commands" {
    Context "Invoke-DeviceADCommands gets correct device" -ForEach @(
		(Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)
	) {
		It "returns valid build GUID when check in is valid" {
			$buildInfo = @{
				AssetID = "SomethingThatIsntInAD"
			}

			{Invoke-DeviceADCommands -buildInfo $buildInfo} | Should -Throw
		}
		It "Gets device" {
			"$((Invoke-DeviceADCommands -buildInfo $_ -whatif) *>&1)" | Should -beLike ($_.AssetID)
		}
		It "Reverts to hostname if AssetID doesn't exist" {
			$_.AssetID = "Garbage"
			$_.hostname = "TCL001629"
			"$((Invoke-DeviceADCommands -buildInfo $_ -whatif) *>&1)" | Should -beLike "*TCL001629*"
		}
	}
	Context "It performs the correct commands" -ForEach @(
		(Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001117 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001680 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001630 | Get-DeviceBuildData)
	) {
		It "Moves correct device to correct OU" {
			$result = "$((Invoke-DeviceADCommands -buildInfo $_ -whatif -verbose) *>&1)" 
			
			$result | Should -beLike "*$($_.AssetID)*"
			$result | Should -beLike "*Moving*$($_.AssetID)*"
			$result | Should -BeLike "*$($_.OU)*"
		}

		It "Moves correct device to correct OU" {
			$result = "$(Invoke-DeviceADCommands -buildInfo $_ -whatif -verbose *>&1)" 
			
			$result | Should -beLike "*$($_.AssetID)*"

			foreach ($group in $_.groups) {
				$result | Should -beLike "*Adding*$($group)*"
			}
		}
	}

	Context "Duplicate AssetID Removal" -ForEach @(
		(Get-FreshAsset -Name TCL00001629 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001117 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001680 | Get-DeviceBuildData),
		(Get-FreshAsset -Name TCL001630 | Get-DeviceBuildData)
	) {
		It "works" {
			$_ | Remove-DeviceADDuplicate -whatif
		}
	}
}

Describe "Filtering Build Tickets" {
	Context "Getting Tickets pending Building" {
		It "Gets a ticket thats actually pending build" {
			$ticket = "103751"
			$buildInfo = (Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)
			$ogFreshAsset = $buildInfo.freshAsset
			$buildInfo.ticketID = $ticket
			
			$buildInfo.buildState = "In Progress - Device Checked In"
			Write-DeviceBuildTicket -buildInfo $buildInfo
			
			$buildInfo.freshAsset = $ogFreshAsset
			$newGUID = "$(Get-Random -Minimum 1000 -Maximum 100000)"
			$buildInfo.GUID = $newGUID
			$buildInfo.buildState = "In Progress - Device Checked In"
			Write-DeviceBuildTicket -buildInfo $buildInfo

			$buildInfo.freshAsset = $ogFreshAsset
			$buildInfo.buildState = "Build Completed"
			Write-DeviceBuildTicket -buildInfo $buildInfo



			Set-FreshTicketStatus -ticketID $ticket -status 15
			$result = Get-PendingBuildTickets
			$result.BuildInfo.ticketID | Should -Contain $ticket
			($result.BuildInfo | ? {$_.ticketID -eq $ticket}).GUID | Should -not -be $newGUID

			Set-FreshTicketStatus -ticketID $ticket -status 5
		}

		It "Doesn't get a ticket that has completed its build" {
			$ticket = "103749"
			$buildInfo = (Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)

			$buildInfo.ticketID = $ticket
			$buildInfo.buildState = "In Progress - Device Checked In"
			Write-DeviceBuildTicket -buildInfo $buildInfo

			$buildInfo.buildState = "Build Completed"
			Write-DeviceBuildTicket -buildInfo $buildInfo


			Set-FreshTicketStatus -ticketID $ticket -status 15


			(Get-PendingBuildTickets).BuildInfo.ticketID | Should -not -Contain $ticket

			Set-FreshTicketStatus -ticketID $ticket -status 5

		}
	}
	Context "Filtering pending tickets" {
		It "doesnt get tickets not waiting on ad cmds" {
			$ticket = "103749"
			$buildInfo = (Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)

			$buildInfo.ticketID = $ticket


			Set-FreshTicketStatus -ticketID $ticket -status 15


			"$(Get-PendingBuildTickets | Select-DevicePendingADCommands)" | Should -not -BeLike "*$ticket*"

			Set-FreshTicketStatus -ticketID $ticket -status 5
		}


		It "does get tickets waiting on ad cmds" {
			$ticket = "103752"
			$buildInfo = (Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)

			$buildInfo.ticketID = $ticket
			
			$buildInfo.buildState = "In Progress - Device Checked In"
			Write-DeviceBuildTicket -buildInfo $buildInfo

			$buildInfo.buildState = "In Progress - Pending AD Commands"
			Write-DeviceBuildTicket -buildInfo $buildInfo

			$newGUID = "$(Get-Random -Minimum 1000 -Maximum 100000)"
			$buildInfo.GUID = $newGUID
			$buildInfo.buildState = "In Progress - Pending AD Commands"
			Write-DeviceBuildTicket -buildInfo $buildInfo


			$buildInfo.buildState = "In Progress - AD Commands Completed"
			Write-DeviceBuildTicket -buildInfo $buildInfo
			

			Set-FreshTicketStatus -ticketID $ticket -status 15

			$result = Get-PendingBuildTickets | Select-DevicePendingADCommands
			$result.ticketID | Should -Contain $ticket
			($result | ? {$_.ticketID -eq $ticket}).GUID | Should -not -be $newGUID


			Set-FreshTicketStatus -ticketID $ticket -status 5
		}

		It "doesnt get tickets not waiting onrename cmds" {
			$ticket = "103749"
			$buildInfo = (Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)

			$buildInfo.ticketID = $ticket


			Set-FreshTicketStatus -ticketID $ticket -status 15


			"$(Get-PendingBuildTickets | Select-DevicePendingOldADCompRemoval)" | Should -not -BeLike "*$ticket*"

			Set-FreshTicketStatus -ticketID $ticket -status 5
		}


		It "does get tickets waiting on renamecmds" {
			$ticket = "103752"
			$buildInfo = (Get-FreshAsset -Name TCL001629 | Get-DeviceBuildData)

			$buildInfo.ticketID = $ticket
			
			$buildInfo.buildState = "In Progress - Device Checked In"
			Write-DeviceBuildTicket -buildInfo $buildInfo

			$buildInfo.buildState = "In Progress - Pending Old AD Computer Cleanup"
			Write-DeviceBuildTicket -buildInfo $buildInfo

			$newGUID = "$(Get-Random -Minimum 1000 -Maximum 100000)"
			$buildInfo.GUID = $newGUID
			$buildInfo.buildState = "In Progress - Pending Old AD Computer Cleanup"
			Write-DeviceBuildTicket -buildInfo $buildInfo


			$buildInfo.buildState = "In Progress - Old AD Computer Cleanup Completed"
			Write-DeviceBuildTicket -buildInfo $buildInfo
			

			Set-FreshTicketStatus -ticketID $ticket -status 15

			$result = Get-PendingBuildTickets | Select-DevicePendingOldADCompRemoval
			$result.ticketID | Should -Contain $ticket
			($result | ? {$_.ticketID -eq $ticket}).GUID | Should -not -be $newGUID

			Set-FreshTicketStatus -ticketID $ticket -status 5

		}
	}
}