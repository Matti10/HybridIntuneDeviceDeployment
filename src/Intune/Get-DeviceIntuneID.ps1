function Get-DeviceIntuneID {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter()]
        $intuneIDRegPath = $DeviceDeploymentDefaultConfig.Intune.IntuneIDRegPath,

		[Parameter()]
        $intuneIDRegKey = $DeviceDeploymentDefaultConfig.Intune.IntuneIDRegKey
	)


    begin {
        $errorList = @()
    }
    process {
        if ($PSCmdlet.ShouldProcess("")) {
            try {
				return Get-ItemPropertyValue -Path $intuneIDRegPath -Name $intuneIDRegKey -Verbose:$VerbosePreference
            }
            catch {
                $errorList += $_
                Write-Error $_
            }
        }
    }
    end {
        if ($errorList.count -ne 0) {
            Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
        }
    }	
}