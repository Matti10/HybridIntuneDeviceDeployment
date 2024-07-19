function Test-OOBE {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (

	)

	begin {
		$errorList = @()
	}
	process {
		if ($PSCmdlet.ShouldProcess((hostname))) {
			try {
				#check if the device in is OOBE
				$oobe = $false
				$procUsers = (Get-Process -IncludeUserName -Verbose).UserName
				foreach ($user in $procUsers)
				{
					if($user -like "*defaultUser*")
					{
						$oobe = $true
						break
					}
				}
				
				return $oobe
			}
			catch {
				$errorList += $_
				Write-Error $_

				return $false
			}
		} else {
			return $true
		}
	}
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}	
}