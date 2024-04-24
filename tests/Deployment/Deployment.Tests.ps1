BeforeAll {

    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Script-Dev*" -or "" -eq $PSCommandPath ) {
        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceManagment\TriCare-DeviceManagment.psm1"  -Force
        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1"  -Force
    } else {
        Import-Module TriCare-Common | Out-Null
        Import-Module TriCare-DeviceManagment | Out-Null
    }

    $defaultConfig = Get-DeviceManagementDefaultConfig

	$API_key = Get-KVSecret -KeyVault "tc-ae-d-kv" -Secret "freshservice-apikey-matt"

}

Describe "Get-DeviceBuildData" {
    Context "Error Handling" {
		It "Errors meaningfully if no search paramaters are provided" {
			{Get-DeviceBuildData -API_Key "aKey" -identity "" -serialNum ""} | Should -Throw
		}

		It "Errors meaningfully if no API Key is provided" {
			{Get-DeviceBuildData -API_Key $null -identity "" -serialNum ""} | Should -Throw
		}
	}

	Context "Getting data" {
		It "Returns info for devices when searching by serial number" -ForEach @(
			"016401921253",
			"015440921053",
			"013214921053",
			"019051921253",
			"017348921253",
			"017384921253",
			"016439921253",
			"018943921253",
			"5WPJ504",
			"4WPJ504",
			"2WPJ504",
			"BVPJ504"
		) {
			(Get-DeviceBuildData -API_Key $API_key -serialNum $_).ticketID | Should -not -BeNullOrEmpty
		}
		It "Returns info for devices when searching by name" -ForEach @(
			"TCL000845",
			"TCL001633",
			"TCL001637",
			"TCL001632",
			"TCL001635",
			"TCL001634"
		) {
			Get-DeviceBuildData -API_Key $API_key -identity $_ | Should -not -BeNullOrEmpty
		}
		It "Returns null for devices with no associated tickets" -ForEach @(
			"TCL000437",
			"TCL000368",
			"TCL000326",
			"TCL000328"
		) {
			Get-DeviceBuildData -API_Key $API_key -identity $_ -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
		}
		It "Returns the newest of many build tickets" {
			(Get-DeviceBuildData -API_Key $API_key -identity TCL000845).ticketID | Should -Be "100900"
		}

		It "only returns build tickets" {
			(Get-DeviceBuildData -API_Key $API_key -identity TCL000845).ticketID | Should -Be "100900"
		}

		It "returns the correct Data" {
			$correct = @{
				serialNumber= ""
				build= "eCase"
				OU= "OU=Head Office,OU=eCase,OU=TriCare-Computers,DC=tricaread,DC=int"
				ticketID= "100900"
				AssetID= "TCL000845"
				type= "Desktop PC"
			}
			$data = Get-DeviceBuildData -API_Key $API_key -identity TCL000845
			
			foreach ($key in $correct.Keys)
			{
				$data."$($key)" | Should -be $correct."$($key)"
			}
		}
	}
}


Describe "Resolve Device OU" {
	Context "Returns correct OU" -ForEach @(
		@{name="TCL000845"; OU="OU=Head Office,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001425";OU="OU=UMGR,OU=ACR,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL000994";OU="OU=PTVN,OU=ACR,OU=CCTV Clients,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001347";OU="OU=ASHG,OU=eCase,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001112";OU="OU=MERM,OU=eCase,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001383";OU="OU=WLAC,OU=eCase,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001652";OU="OU=Head Office,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001429";OU="OU=UMGR,OU=ACR,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001460";OU="OU=UMGR,OU=ACR,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001209";OU="OU=PTVN,OU=iAuditor,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001451";OU="OU=UMGR,OU=ACR,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"}
		@{name="TCL001517";OU="OU=UMGR,OU=ACR,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"}
	){
		it "Returns expected OU "{

			$buildTickets = Get-FreshAssetsTickets -API_Key $API_Key -name $name
			
			if ($null -ne $buildTickets) {
				# filter non build tickets out
				$buildTickets = $buildTickets
				| Where-Object {
					foreach ($pattern in $defaultConfig.Deployment.buildTicketNamePatterns) {
						if ($_.request_details -like $pattern) {
							return $true
						}
					}
					return $false
				}

				#get the newest ticket
				$buildTicketID = ($buildTickets | Sort-Object -Property updated_at -Descending)[0]."request_id".split("-")[1] # request id has a prefix "SR-"/"INC-" 

				Write-Host "$name - $buildTicketID"

				$buildDetails = (Get-FreshTicketsRequestedItems -API_Key $API_Key -ticketID $buildTicketID).custom_fields

				$foundOU = Get-DeviceBuildOU -build $buildDetails.hardware_use_build_type -facility $buildDetails.facility[0]

				Get-ADOrganizationalUnit -Identity $foundOU -ErrorAction stop

				$foundOU | Should -be $OU
			}
		}
	}
}

Describe "New BuildInfoObj" {
	Context "error Handling" {
		it "errors if no ou or location is inputted" {
			{New-BuildInfoObj -AssetId "e" -type "e" -build "e" -ticketID "e"} | Should -throw
		}
		it "no errors if only location is inputted" {
			{New-BuildInfoObj -AssetId "e" -type "e" -build "e" -ticketID "e" -freshLocation "someLocation"} | Should -not -throw
		}
		it "no errors if only OU is inputted" {
			{New-BuildInfoObj -AssetId "e" -type "e" -build "e" -ticketID "e" -ou "notNull"} | Should -not -throw
		}
	}
	Context "creates a valid object" -ForEach @(
		@{
			AssetID = "TCL00TEST"
			serialNumber = ""
			type = "testType"
			build= "Facility Management/Operations"
			OU = "OU=UMGR,OU=ACR,OU=Operational Device,OU=TriCare-Computers,DC=tricaread,DC=int"
			ticketID = "123456"
		}
	) {
		it "Creates correct object with OU"{

			$buildObj = New-BuildInfoObj -AssetID $AssetID -type $type -build $build -OU $OU -ticketID $ticketID

			foreach ($key in $buildObj.Keys)
			{
				$buildObj."$($key)" | Should -be $_."$($key)"
			}
		}

		it "Creates correct object with freshLocation"{

			$buildObj = New-BuildInfoObj -AssetID $AssetID -type $type -build $build -ticketID $ticketID -freshLocation "11000342568"

			foreach ($key in $buildObj.Keys)
			{
				$buildObj."$($key)" | Should -be $_."$($key)"
			}

		}
	}
}