BeforeDiscovery {


    $DebugPreference = 'SilentlyContinue'
}
BeforeAll {
    Set-StrictMode -Version 2.0
    $DebugPreference = 'SilentlyContinue'

    # <# --- Import TriCare-Common --- #>
    # if ($PSCommandPath -like "*Mwinsen\Script-Dev*" -or "" -eq $PSCommandPath ) {
        # Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1" -force -ErrorAction "Continue"
        # Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1"  -Force -ErrorAction "Continue"
    # } else {
    #     Import-Module TriCare-Common
    #     Import-Module .\TriCare-DeviceDeployment | Out-Null
    # }

    $config = Get-DeviceDeploymentDefaultConfig


}
Describe "General Setup" {
    Context "Default Config"{
        It "Sets default config varible" {
			Get-DeviceDeploymentDefaultConfig | Should -Not -BeNullOrEmpty
		}
    }
}

BeforeDiscovery {
    Set-StrictMode -Version 2.0

    <# --- Import TriCare-Common --- #>
    if ($PSCommandPath -like "*Mwinsen\Script-Dev*" -or "" -eq $PSCommandPath ) {
        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1" -ErrorAction "Continue" #-force
        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1" -ErrorAction "Continue"  #-Force
    } else {
        Import-Module TriCare-Common -ErrorAction "Continue"
        Import-Module .\TriCare-DeviceDeployment | Out-Null -ErrorAction "Continue"
    }
    $config = Get-DeviceDeploymentDefaultConfig

}

Describe "Build Data" {
    Context "BuildInfo Object" -ForEach @(
        @{name = "someName"; type = "someType"; build = "SomeBuild"; ticketID = "SomeID"; freshLoc = "11000343256"; OU = "someOU";serialNumber = "1234567890";}
    ){
        It "Should return an object with same inputs" {
            $result = New-BuildInfoObj -AssetId $name -serialNumber $serialNumber -type $type -build $build -ticketID $ticketID -freshLocation $freshLoc -OU $OU -freshAsset ([PSCustomObject]@{Name = "Value"}) -groups @("A","B")

            $result.AssetID | Should -be $name
            $result.serialNumber | Should -be $serialNumber
            $result.type | Should -be $type
            $result.build | Should -be $build
            $result.OU | Should -beLike "*OU*"
            $result.ticketID | Should -be $ticketID
            $result.buildState | Should -be (Get-DeviceDeploymentDefaultConfig).TicketInteraction.BuildStates.initialState.message
            
        }
    }

    Context "OU Resolution" -ForEach @(
        $config.Deployment.buildTypeCorrelation | ForEach-Object {
            $tempBuild = $_
            $config.Deployment.locationCorrelation | ForEach-Object {
                if (
                    !(($tempBuild.OU -like "*iAuditor*" -and $_.dept -notlike "*ACR*") -or
                    ($tempBuild.OU -like "*Litmos*" -and $_.dept -notlike "*ACR*") -or
                    ($tempBuild.buildType -like "*Head Office*" -and $_.location -notlike "*Head Office*") -or
                    ($_.location -like "*Head Office*" -and $tempBuild.buildType -notlike "*Head Office*") -or
                    ($tempBuild.OU -like "*eCase*" -and $_.dept -notlike "*ACR*"))
                    ) {
                        return @{
                            build = $tempbuild;
                            deptOU = $_.dept;
                            locOU = $_.location
                            buildOU = $tempBuild.OU; 
                            freshID = $_
                            hasDept = $tempBuild.hasDepartment
                        }
                    }
            }
        }
    ) {
        It "Returns the OU for the correct site" {
            $result = Get-DeviceBuildOU -build $build -facility $freshID
            $result | Should -beLike "*$buildOU*"
            if ($hasDept) {$result | Should -beLike "*$deptOU*"}
            $result | Should -beLike "*$locOU*"
        }  
        It "Returns an OU that actually exists" {
            $result = Get-DeviceBuildOU -build $build -facility $freshID
            try {
                Get-ADOrganizationalUnit -identity $result -ErrorAction Stop
            } catch {
                Write-Error -ErrorAction SilentlyContinue -Message ""
            }

            {Get-ADOrganizationalUnit -identity $result -ErrorAction Stop} | Should -not -throw
        }
    }

    Context "Group Resolution" -ForEach @(
        $config.Deployment.buildTypeCorrelation | ForEach-Object {
            $tempBuild = $_
            $config.Deployment.locationCorrelation | ForEach-Object {
                return @{build=$tempBuild; facility = $_}
            }
        }
    ) {
        It "Collects the correct groups" {
            $groups = Get-DeviceBuildGroups -build $build -facility $facility
            $correctGroups = @($build.groups + $facility.groups)

            $groups.count | Should -be $correctGroups.count

            foreach ($group in $correctGroups) {
                $group | Should -BeIn $groups
            }
        }

        It "is a group that actually exists" {
            $groups = Get-DeviceBuildGroups -build $build -facility $facility

            $groups | ForEach-Object {
                $group = $_
                {Get-ADGroup -Identity $group -ErrorAction Stop} | Should -not -Throw
            }
        }
    }

    
    Context "Getting Build Data from Fresh" {
    
        It "Returns null or errors (depending on erroraction) when a device has no build tickets" -ForEach @(
            (Get-FreshAsset -name "TCM0150"),
            (Get-FreshAsset -name "TCM0142"),
            (Get-FreshAsset -name "TCM0143"),
            (Get-FreshAsset -name "TCM0147"),
            (Get-FreshAsset -name "TCM0148")
        ) {
            Get-DeviceBuildData -FreshAsset $_ -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

            {Get-DeviceBuildData -FreshAsset $_ -ErrorAction Stop} | Should -Throw
        }

        It "Gets the newest of many build tickets, and only build tickets" -ForEach @(
            @{Identity = Get-FreshAsset -name "TCL000845"; correctTicket = "100900"}
        ) {
            (Get-DeviceBuildData -FreshAsset $identity).ticketID | Should -be $correctTicket
        }

        It "Gets Correct Info for Devices" -ForEach @(
            # Get-FreshAsset -all
            # | ? {
            #     $null -ne ($_.Name | Get-DeviceBuildData -ErrorAction SilentlyContinue)
            # }
            (Get-FreshAsset -name TCL000845),
            (Get-FreshAsset -name TCL001629),
            (Get-FreshAsset -name TCL001242),
            (Get-FreshAsset -name TCL001650)
        ) {
            $result = Get-DeviceBuildData -FreshAsset $_

            $result.AssetID | Should -be $_.Name
            $result.type | Should -not -BeNullOrEmpty
            "$($config.Deployment.buildTypeCorrelation.buildType)" | Should -beLike "*$($result.build)*"
            $result.OU | Should -beLike "*OU=*OU=*"
            Get-FreshTicketsRequestedItems -ErrorAction stop -ticketID $result.ticketID | Should -not -BeNullOrEmpty
            $result.buildState | Should -be $config.TicketInteraction.BuildStates.initialState.message
        }
        
    }

    Context "Asset ID Mutex" {
        It "Gets the fresh custom object" {
            (Get-FreshCustomObject -objectID "11000002068").bo_display_id | Should -be "2"
        }

        It "Sets the fresh custom object" {

            $setValue = "Test34"
            $ogRecord = Get-DeviceAssetIDMutex

            $ogRecord.SetBy = $setValue

            Set-DeviceAssetIDMutex -mutex $ogRecord

            (Get-FreshCustomObject -objectID "11000002068").SetBy | Should -be "$setValue"
        }

        It "Protects the Mutex and has a valid setby" {
            Repair-DeviceAssetIDMutex

            $protected = Protect-DeviceAssetIDMutex

            $mutex = Get-DeviceAssetIDMutex

            $mutex.currentlyaccessed | Should -be $true
            $mutex.setby | Should -be $protected.setBy
        }

        It "Unprotects the Mutex and has a valid setby" {
            Repair-DeviceAssetIDMutex

            $protected = Protect-DeviceAssetIDMutex

            $unprotected = Unprotect-DeviceAssetIDMutex -mutex $protected

            $mutex = Get-DeviceAssetIDMutex

            $mutex.currentlyaccessed | Should -be $false
            $mutex.setby | Should -be $unprotected.setBy
        }
        
        It "Handles the remote value changing before set can be completed" {
            $mutex = Protect-DeviceAssetIDMutex
            $otherMutex = Protect-DeviceAssetIDMutex
            Set-DeviceAssetIDMutex -mutex $otherMutex
            Set-DeviceAssetIDMutex -mutex $mutex
            
            
            Repair-DeviceAssetIDMutex
        }
    }

    

    Context "Getting Asset ID" {
        It "Returns a device's curent asset ID if it already exists" -ForEach (@(
            @{serial="0F00GP5220801J";AssetID="TCL001680"},@{serial="036990191853";AssetID="TCL000878"},@{serial="5b3ljl3";AssetID="TCl001393"},@{serial="011416181353";AssetID="TCL000670"},@{serial="d04GYX3";AssetID="TCL001425"},@{serial="474GYX3";AssetID="TCL001533"},@{serial="3456KL3";AssetID="TCL001624"},@{serial="005299304953";AssetID="TCL001230"},@{serial="3BYTZL2";AssetID="TCL000511"},@{serial="032464211253";AssetID="TCL001149"},@{serial="J34GYX3";AssetID="TCL001444"},@{serial="021969114353";AssetID="TCL001352"},@{serial="046938583953";AssetID="TCL000708"},@{serial="015578204953";AssetID="TCL001144"},@{serial="364GYX3";AssetID="TCL001485"},@{serial="8LXG6Z3";AssetID="TCL001588"},@{serial="HMY3R33";AssetID="TCL001029"},@{serial="9WTGYD3";AssetID="TCL001156"},@{serial="974GYX3";AssetID="TCL001528"},@{serial="BVPJ504";AssetID="TCL001633"},@{serial="3JVZVV2";AssetID="TCL000840"},@{serial="007453272353";AssetID="TCL000895"},@{serial="022637181353";AssetID="TCL001639"},@{serial="CJXG6Z3";AssetID="TCL001594"},@{serial="HDB7WT2";AssetID="TCL000820"},@{serial="008728383053";AssetID="TCL000717"},@{serial="12T90J2";AssetID="TCL000413"},@{serial="075374201353";AssetID="TCL001042"},@{serial="036208204853";AssetID="TCL001177"},@{serial="054624703453";AssetID="TCL001093"},@{serial="023739414753";AssetID="TCL001369"},@{serial="3KXG6Z3";AssetID="TCL001577"},@{serial="005009792053";AssetID="TCL000964"},@{serial="714GYX3";AssetID="TCL001494"},@{serial="CP3LGX3";AssetID="TCL001315"},@{serial="031329304853";AssetID="TCL001164"},@{serial="gq35sn3";AssetID="TCl001399"},@{serial="012427504753";AssetID="TCL001407"},@{serial="002868480153";AssetID="TCL000546"},@{serial="002342301953";AssetID="TCL001112"},@{serial="011338581753";AssetID="TCL000909"},@{serial="6KXG6Z3";AssetID="TCL001583"},@{serial="J4KX033";AssetID="TCL000994"},@{serial="G74GYX3";AssetID="TCL001516"},@{serial="464GYX3";AssetID="TCL001479"},@{serial="005242114853";AssetID="TCL001340"},@{serial="J24GYX3";AssetID="TCL001431"},@{serial="053954281653";AssetID="TCL000637"},@{serial="006281411053";AssetID="TCL001224"},@{serial="008841703553";AssetID="TCL001110"},@{serial="J44GYX3";AssetID="TCL001441"},@{serial="27CC9V2";AssetID="TCL000858"},@{serial="BJXG6Z3";AssetID="TCL001591"},@{serial="3LXG6Z3";AssetID="TCL001578"},@{serial="046935183953";AssetID="TCL000707"},@{serial="012855715053";AssetID="TCL001354"},@{serial="031549603853";AssetID="TCL001099"},@{serial="H54GYX3";AssetID="TCL001471"},@{serial="G5KT114";AssetID="TCL001856"},@{serial="020082292053";AssetID="TCL000939"},@{serial="374GYX3";AssetID="TCL001515"},@{serial="HWZFBW2";AssetID="TCL000873"},@{serial="005280601453";AssetID="TCL001299"},@{serial="4KXG6Z3";AssetID="TCL001579"},@{serial="D64GYx3";AssetID="TCL001484"},@{serial="062268401453";AssetID="TCL001030"},@{serial="G64GYX3";AssetID="TCL001478"},@{serial="004407690853";AssetID="TCL000866"},@{serial="284GYx3";AssetID="TCL001534"},@{serial="3JZ1WV2";AssetID="TCL000833"},@{serial="JN6C3F3";AssetID="TCL001228"},@{serial="035987304853";AssetID="TCL001172"},@{serial="2FKVKC2";AssetID="TCL000007"},@{serial="65VVK63";AssetID="TCL001087"},@{serial="3JV3WV2";AssetID="TCL000836"},@{serial="334GYX3";AssetID="TCL001498"},@{serial="cq35sN3";AssetID="TCL001398"},@{serial="015284104953";AssetID="TCL001142"},@{serial="934GYX3";AssetID="TCL001450"},@{serial="031254604853";AssetID="TCL001166"},@{serial="048327491353";AssetID="TCL000883"},@{serial="GLXG6Z3";AssetID="TCL001604"},@{serial="454GYX3";AssetID="TCL001505"},@{serial="1cwxTn3";AssetID="TcL001616"},@{serial="020593205053";AssetID="TCL001151"},@{serial="017348921253";AssetID="TCL001654"},@{serial="3JYYVV2";AssetID="TCL001661"},@{serial="010311162253";AssetID="TCL000852"},@{serial="354GYX3";AssetID="TCL001495"},@{serial="003745215153";AssetID="TCL001271"},@{serial="007794114353";AssetID="TCL001241"},@{serial="3JT3WV2";AssetID="TCL000839"},@{serial="038542603253";AssetID="TCL001062"},@{serial="018102215053";AssetID="TCL001381"},@{serial="019346514353";AssetID="TCL001375"},@{serial="324GYX3";AssetID="TCL001427"},@{serial="056683794753";AssetID="TCL001086"},@{serial="254GYX3";AssetID="TCL001465"},@{serial="144GYX3";AssetID="TCL001446"},@{serial="033612674753";AssetID="TCL000530"},@{serial="27BD9V2";AssetID="TCL000848"},@{serial="7KXG6Z3";AssetID="TCL001585"},@{serial="031699703853";AssetID="TCL001102"},@{serial="BY68WT2";AssetID="TCL000798"},@{serial="H04GYX3";AssetID="TCL001455"},@{serial="050798670953";AssetID="TCL000945"},@{serial="854gyx3";AssetID="TCL001540"},@{serial="066552491253";AssetID="TCL000863"},@{serial="644GYX3";AssetID="TCL001438"},@{serial="F34GYX3";AssetID="TCL001439"},@{serial="031778203853";AssetID="TCL001101"},@{serial="033034174753";AssetID="TCL000532"},@{serial="J54GYX3";AssetID="TCL001502"},@{serial="27BH9V2";AssetID="TCL000845"},@{serial="764Q253";AssetID="TCL001051"},@{serial="554GYX3";AssetID="TCL001542"},@{serial="004028715153";AssetID="TCL001267"},@{serial="053182294753";AssetID="TCL001019"},@{serial="007439591553";AssetID="TCL000882"},@{serial="030021190253";AssetID="TCL000789"},@{serial="001903115153";AssetID="TCL001568"},@{serial="003800315153";AssetID="TCL001248"},@{serial="277C9V2";AssetID="TCL001276"},@{serial="13380J2";AssetID="TCL000418"},@{serial="021086414353";AssetID="TCL001387"},@{serial="014736781353";AssetID="TCL000658"},@{serial="0F00GSJ220801J";AssetID="TCL001675"},@{serial="044785704853";AssetID="TCL001212"},@{serial="F54GYX3";AssetID="TCL001487"},@{serial="012808215053";AssetID="TCL001346"},@{serial="054080481653";AssetID="TCL000621"},@{serial="053603494753";AssetID="TCL001033"},@{serial="F44GYX3";AssetID="TCL001440"},@{serial="J64GYX3";AssetID="TCL001503"},@{serial="019271114353";AssetID="TCL001342"},@{serial="H5KT114";AssetID="TCL001853"},@{serial="744GYX3";AssetID="TCL001447"},@{serial="006690711053";AssetID="TCL001222"},@{serial="019051921253";AssetID="TCL001655"},@{serial="048511201653";AssetID="TCL001071"},@{serial="012897115053";AssetID="TCL001380"},@{serial="046199605253";AssetID="TCL001113"},@{serial="046982683953";AssetID="TCL000700"},@{serial="2WGSFX3";AssetID="TCL001314"},@{serial="072397793753";AssetID="TCL001006"},@{serial="FLXG6Z3";AssetID="TCL001601"},@{serial="114GYX3";AssetID="TCL001509"},@{serial="BKXG6Z3";AssetID="TCL001592"},@{serial="834GYX3";AssetID="TCL001421"},@{serial="022423103253";AssetID="TCL001081"},@{serial="74J6NG3";AssetID="TCL001259"},@{serial="3CWXTN3";AssetID="TCL001613"},@{serial="B24gYx3";AssetID="TCL001538"},@{serial="F14GYX3";AssetID="TCL001430"},@{serial="6b3ljl3";AssetID="TCL001392"},@{serial="044017504853";AssetID="TCL001192"},@{serial="043085104853";AssetID="TCL001202"},@{serial="013701201153";AssetID="TCL001121"},@{serial="G24GYX3";AssetID="TCL001519"},@{serial="012925201153";AssetID="TCL001405"},@{serial="534GYX3";AssetID="TCL001456"},@{serial="003920715153";AssetID="TCL001260"},@{serial="C04GYX3";AssetID="TCL001524"},@{serial="021863114353";AssetID="TCL001388"},@{serial="019995292053";AssetID="TCL000916"},@{serial="027358304153";AssetID="TCL001125"},@{serial="031749403853";AssetID="TCL001088"},@{serial="059985681353";AssetID="TCL000623"},@{serial="5KXG6Z3";AssetID="TCL001581"},@{serial="003640174053";AssetID="TCL001147"},@{serial="035426164253";AssetID="TCL000897"},@{serial="CLXG6Z3";AssetID="TCL001596"},@{serial="FPTY733";AssetID="TCL001022"},@{serial="015233704553";AssetID="TCL001096"},@{serial="012953115053";AssetID="TCL001377"},@{serial="012736215053";AssetID="TCL001356"},@{serial="045616604853";AssetID="TCL001198"}) | Get-Random -Count 50) {
            (Get-DeviceAssetID -serialNumber $serial).AssetID | Should -be $AssetID
            Start-Sleep -Milliseconds 200
        
        }

        It "Returns the next asset id if serial is unknown" -ForEach @(
            "someSerialThatDoesntExist10"
        ) {
            (Get-DeviceAssetID -serialNumber $_).AssetID | Should -be "TCL001860" #this will need to be manually changed
        }

        It "Returns the next asset id if serial is unknown" -ForEach @(
            "someSerialThatDoesntExist10"
        ) {
            Get-DeviceAssetID -serialNumber $_ -disaplyUserOutput
        }
    }
    Context "Device Registration in Fresh" {
        It "Finds the closest fresh product" -ForEach @(
            "Surface Pro 7",
            "Surface Pro",
            "Surface 4 Pro",
            "Optiplex",
            "Optiplex 7040",
            "Optiplex 7080",
            "Latitude"
            "Latitude 5590"
            "Latitude 6969"
        ) {
            (Find-FreshProductClosestMatch -model $_).Name | Should -beLike "*$($_.split(" ")[0])*"
        }
        It "Has some sort of mutex to manage concurrent access to next asset" {
            $results = (
                1..10 | ForEach-Object -ThrottleLimit 10 -Parallel {
                    
                    <# --- Import TriCare-Common --- #>
                    if ($PSCommandPath -like "*Mwinsen\Script-Dev*" -or "" -eq $PSCommandPath ) {
                        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-Common\TriCare-Common.psm1" -force
                        Import-Module "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\TriCare-DeviceDeployment.psm1" -Force
                    } else {
                        Import-Module .\TriCare-DeviceDeployment | Out-Null
                        Import-Module TriCare-Common
                    }

                    Write-Host (Register-DeviceWithFresh -localDeviceInfo (Get-DeviceLocalData -whatif) -verbose).Name

                } 
            )

            $results | % {
                $currentValue = $_
                ($results | ? {$_ -eq $currentValue}).count | Should -Be 1
            }
        }
    }
}
Describe "BuildTicket Interaction" {
    Context "Creating Progress Notes" {
        It "Outputs correct HTML" -ForEach @(
            (Get-FreshAsset -name "TCL000845")
        ) {
            New-Item -Name "BuildNoteHTML.html" -Path "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\tests" -Force -Value (
                $_ | Get-DeviceBuildData | Write-DeviceBuildTicket -whatif -Message "This is some test message"
            )
        }

        It "Creates a note" -ForEach @(
            (Get-FreshAsset -name "TCL000845")
        ) {
            $_ | Get-DeviceBuildData | Write-DeviceBuildTicket -message "Test Test eTHGSDKJFHDSGJFSGDKHJFHF"
        }

        It "Outputs correct HTML when erroring" -ForEach @(
            (Get-FreshAsset -name "TCL000845")
        ) {
            $buildData = $_ | Get-DeviceBuildData

            $anError = $null

            try {Get-Content -path thisPathDoesntExist -ErrorAction stop} catch {$anError = $_}
        
            New-Item -Name "BuildErrorNoteHTML.html" -Path  "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\tests" -Force -Value (
                $buildData| Write-DeviceBuildError -whatif -errorObject $anError -logPath "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\tests\DeviceDeployment.Tests.ps1" -additionalInfo "This Is a Test"
            )
        }

        It "Outputs correct HTML when erroring WO errorObj" -ForEach @(
            (Get-FreshAsset -name "TCL000845")
        ) {
            $buildData = $_ | Get-DeviceBuildData

            $anError = $null

            try {Get-Content -path thisPathDoesntExist -ErrorAction stop} catch {$anError = $_}
        
            New-Item -Name "BuildErrorNoteHTML-NoErrorObj.html" -Path  "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\tests" -Force -Value (
                $buildData| Write-DeviceBuildError -whatif -logPath "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\tests\DeviceDeployment.Tests.ps1" -additionalInfo "This Is a Test"
            )
        }

        It "creates a legit note when erroring" -ForEach @(
            (Get-FreshAsset -name "TCL000845")
        ) {
            $buildData = $_ | Get-DeviceBuildData

            $anError = $null

            try {Get-Content -path thisPathDoesntExist -ErrorAction stop} catch {$anError = $_}
        
            $buildData | Write-DeviceBuildError -logPath "\\tricaread\public\UsersH$\Mwinsen\Script-Dev\TriCare-DeviceDeployment\tests\DeviceDeployment.Tests.ps1" -additionalInfo "This Is a Test"
            
        }
    }
    Context "Testing if AD Command are completed" {
        It "Returns false if no relevant notes exist" -ForEach @(
            (Get-DeviceBuildData -FreshAsset (Get-FreshAsset -name "TCL001629")),
            (Get-DeviceBuildData -FreshAsset (Get-FreshAsset -name "TCL000845"))
        )  {
            Test-DeviceADCommandCompletion -BuildInfo $_ | Should -be $false
        }

        It "Returns false if ad commands aren't completed" -ForEach @(
            (Get-DeviceBuildData -FreshAsset (Get-FreshAsset -name "TCL000845"))
        )  {
            $_.GUID = "TestRun-$((Get-Date).ToFileTimeUtc())"
            
            $_ | Write-DeviceBuildTicket
            Test-DeviceADCommandCompletion -BuildInfo $_ | Should -be $false
        }

        It "Returns true if AD commands are completed" -ForEach @(
            (Get-DeviceBuildData -FreshAsset (Get-FreshAsset -name "TCL000845"))
        )  {
            $_.GUID = "TestRun-$((Get-Date).ToFileTimeUtc())"
            $_.buildState = $config.TicketInteraction.BuildStates.adCompletedState.message
            
            $_ | Write-DeviceBuildTicket
            Test-DeviceADCommandCompletion -BuildInfo $_ | Should -be $true
        }

        
        It "Returns false if ONLY PREVIOUS ad commands are completed" -ForEach @(
            (Get-DeviceBuildData -FreshAsset (Get-FreshAsset -name "TCL000845"))
        )  {
            $_.GUID = "TestRun-$((Get-Date).ToFileTimeUtc())"
            $_.buildState = $config.TicketInteraction.BuildStates.adCompletedState.message
            $_ | Write-DeviceBuildTicket
            
            Start-Sleep -Seconds 1
            $_.GUID = "TestRun-$((Get-Date).ToFileTimeUtc())"

            
            Test-DeviceADCommandCompletion -BuildInfo $_ | Should -be $false
        }
    }
}

Describe "Generic" {
    Context "Device Correlation" {
        It "Gets correct facility"  -ForEach @($config.Deployment.locationCorrelation) {
            "$((Find-DeviceCorrelationInfo -build "Head Office" -facility $_.freshID).facilityCorrelation)" | Should -be "$($_)"
        }

        It "Gets correct facility"  -ForEach @($config.Deployment.buildTypeCorrelation) {
            "$((Find-DeviceCorrelationInfo -build $_.buildType -facility "11000342556").buildCorrelation)" | Should -be "$($_)"
        }

        It "Errors if no facility or build are found" -ForEach @(
            {Find-DeviceCorrelationInfo -build "Head Office" -facility "someNonExistentFacility" -errorAction Stop},
            {Find-DeviceCorrelationInfo -build "SomeNonExistenBuild" -facility "someNonExistentFacility" -errorAction Stop},
            {Find-DeviceCorrelationInfo -build "SomeNonExistenBuild" -facility "11000342556" -errorAction Stop}
        ) {
            {& $_} | Should -Throw
        }
    }
}

Describe "Local Commands" {
    Context "Blocking Local Shutdown" {
        It "Creates the blocker job" {
            $job = Block-DeviceShutdown

            (Get-Job).name| Should -Contain "Block-DeviceShutdown"

            Get-Job | ? {$_.Name -like "*Block-DeviceShutdown*"} | Stop-Job
        }

        It "Stops the blocker job" {
            $job = Block-DeviceShutdown

            (Get-Job).name| Should -Contain "Block-DeviceShutdown"

            Unblock-DeviceShutdown

            (Get-Job | ? {$_.Name -eq "Block-DeviceShutdown"}).state | % {$_| Should -be "Stopped"}

        }
    }
    Context "Getting Local Data" {
        it "Gets local data " {
            # This only works on a non-virtual machine
            
            # $systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
            # $model = $systemInfo.model
            # $hostname = $systemInfo.Name
            # $serial =  (Get-CimInstance -ClassName win32_bios).SerialNumber          
            
            # Get-DeviceLocalData
        }
    }

    Context "GPupdates" {
        It "doesn't error and creates reg key" {
            {Invoke-GPUpdate -waitTime 0} | Should -not -Throw
            (Get-ItemProperty -Path $config.Generic.RunOnceRegistryPath | Get-Member).Name | Should -Contain "GPUpdate"

            Remove-ItemProperty -Path $config.Generic.RunOnceRegistryPath -Name GPUpdate
        }

    }
}


Describe "Windows Updates" {
    Context "Installing Preqs" {
        It "Installs NuGet if not installed - This only works on device that don't already have nuget" {

            If ((Get-PackageProvider).Name -notContains "nuget") {
                Initialize-DeviceWindowsUpdate -whatIf -verbose *>&1 | Should -beLike "*Installing*"
            } else {
                Initialize-DeviceWindowsUpdate -whatIf -verbose *>&1 | Should -not -beLike "*Installing*"
            }
        }


        It "Installs NuGgett if not installed - This only works on device that don't already have nuggett" {

            "$(Initialize-DeviceWindowsUpdate -packageProviderName "nuggett" -whatIf -verbose -errorAction SilentlyContinue *>&1)" | Should -beLike "*Installing*"
        }


        It "Installs PSWindows update if not installed" {
            Uninstall-Package -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue

            Initialize-DeviceWindowsUpdate

            (Get-Package).Name | Should -Contain "PSWindowsUpdate"
        }
    }
    
    Context "Installing windows updates - This needs to be tested on a new machine..." {
        It "Installs updates" {
            Update-DeviceWindowsUpdate 
        }
    }
}

Describe "Bloatware Removal" {
    Context "As above" {
        It "searches all expected locations" {
            $searchLocs = "*HKLM*Uninstall*","*HKEY_USERS\.DEFAULT*Uninstall*","*HKEY_USERS\S-1-5-19*Uninstall*","*HKEY_USERS\S-1-5-20*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-14532*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-14532_Classes*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-18187*Uninstall*","*HKEY_USERS\S-1-5-21-3142357425-3434510276-3173183097-18187_Classes*Uninstall*","*HKEY_USERS\S-1-5-80-1184457765-4068085190-3456807688-2200952327-3769537534*Uninstall*","*HKEY_USERS\S-1-5-80-1184457765-4068085190-3456807688-2200952327-3769537534_Classes*Uninstall*","*HKEY_USERS\S-1-5-80-1835761534-3291552707-3889884660-1303793167-3990676079*Uninstall*","*HKEY_USERS\S-1-5-80-1835761534-3291552707-3889884660-1303793167-3990676079_Classes*Uninstall*","*HKEY_USERS\S-1-5-18*Uninstall*"

            $result = "$(Remove-DeviceBloatware -verbose -whatif -errorAction "SilentlyContinue" *>&1)"

            foreach ($loc in $searchLocs) {
                $result | Should -Belike "*Searching$loc"
            }
            
        }

        It "Removes correct software without erroring (test on real device)" {
            Remove-DeviceBloatware -verbose -errorAction SilentlyContinue
        }
    }
}

Describe "Dell Command Update" {
    Context "ee" {
        It "Discovers Command update if its installed" {
            if ("$(((Get-ChildItem Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Get-ItemProperty) | Select DisplayName).DisplayName)" -like "*Dell Command*") {
                Test-DeviceDellCommandUpdate | Should -not -be $false
            } else {
                Test-DeviceDellCommandUpdate | Should -be $false
            }
        }

        It "Updates drivers correctly (must be tested on dell device)" {
            $result = "$(Invoke-DeviceDellCommandUpdateUpdates *>&1)"

            if ( $result -like "*The program exited with return code: 1*") {
                $result | Should -beLike "*The program exited with return code: 1*"
            } else {
                $result | Should -beLike "*The program exited with return code: 0*"
            }
        }
    }
}

Describe "Intune Sync" {
    Context "Intune Sync" {
        It "Errors when company portal isnt installed (will only pass on DWDV or brand new machines)" {
            {Invoke-DeviceCompanyPortalSync -errorAction Stop} | Should -Throw
        }

        It "Starts the correct task when company portal is installed" {
            Invoke-DeviceCompanyPortalSync

            (Get-ScheduledTask | Where-Object {$_.TaskName -eq $syncTaskName}).state | Should -be "Running"
        }
    }
}

Describe "Cleanup" {
    Context "Cleanup" {
        It "Doesn't remove log files" {
            New-Item -Path "$($config.Generic.buildPCRootPath)\Modules\SomeTestModule\someGarbage.ps1"  -force -Value "someTestValue"
            New-Item -Path "$($config.Logging.buildPCLogPath)\someLog.txt" -Value "someTestValue" -force 
            New-Item -Path "$($config.Generic.buildPCRootPath)\someRandom.txt" -Value "someTestValue" -force 

            Remove-DeviceDeploymentTempData -verbose

            $items = Get-ChildItem -Path $config.Generic.buildPCRootPath -Recurse -Depth 100

            $items | Should -not -BeNullOrEmpty
            $items | % {
                $_.FullName | Should -beLike "*$($config.Logging.buildPCLogPath)*"
            }
        }
    }
}

Describe "Device User Communication" {
    Context "Creating Popups" {
        It "creates a popup" -ForEach @(
            $config.DeviceUserInteraction.messageBoxConfigurations.Exclamation,
            $config.DeviceUserInteraction.messageBoxConfigurations.Retry,
            $config.DeviceUserInteraction.messageBoxConfigurations.Information
        ) {
            {Show-DeviceUserMessage -Message "Test" -Title "test" -messageBoxConfigCode $_} | Should -not -Throw
        }
    }
}