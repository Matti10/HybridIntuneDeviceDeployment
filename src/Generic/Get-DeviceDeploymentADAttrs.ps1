function Get-DeviceDeploymentADAttrs {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[PSCustomObject]$config = $DeviceDeploymentDefaultConfig
	)

	begin {
		$errorList = @()

		#rec function def
		function Search-ConfigADAttrs {
			[CmdletBinding(SupportsShouldProcess = $true)]
			param (
				[PSCustomObject]$config = $DeviceDeploymentDefaultConfig
			)
			begin {
				$errorList = @()
			}
			process {
				try {
					$attrs = @()

					$properties = ($config | Get-Member) | Where-Object { $_.MemberType -eq "NoteProperty" }

					foreach ($property in $properties) {
						$attrs += Search-ConfigADAttrs -config $config."$($property.name)"
					}

					$properties | Where-Object { $_.Name -like "*adAttr" } | ForEach-Object { $attrs += $config."$($_.Name)" }

					return $attrs
				}
				catch {
					$errorList += $_
					Write-Error $_
				}
			}
			end {
				if ($errorList.count -ne 0) {
					Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
				}
			}	
		}
	}
	process {
		if ($PSCmdlet.ShouldProcess("Getting Config")) {
			try {
				return Search-ConfigADAttrs
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