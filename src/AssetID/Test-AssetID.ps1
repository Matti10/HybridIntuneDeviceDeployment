
<# Documentation
# Name
Test-AssetID

.SYNOPSIS
This cmdlet tests the Asset ID by validating the length and prefix. If there are errors during the process, they are recorded and output at the end of the process.

.DESCRIPTION
The `Test-AssetID` function takes an Asset ID as input and checks whether the length of the Asset ID matches the predefined length and the ID starts with the predefined prefix. If the ID does not satisfy both conditions, the function will return `$false`. If it satisfies both conditions, it will return `$true`.

.PARAMETER AssetID
Specifies the Asset ID to test. This is a mandatory parameter and it can accept its value from the pipeline.

.PARAMETER AssetIDPrefix
Specifies the prefix for the Asset ID. This is not a mandatory parameter and if not specified, it gets its default value from `$DeviceDeploymentDefaultConfig.AssetID.AssetIDPrefix`.

.PARAMETER AssetIDLength
Specifies the length of the Asset ID. This is not a mandatory parameter and if not specified, it gets its default value from `$DeviceDeploymentDefaultConfig.AssetID.AssetIDLength`.

.INPUTS
`[string]$AssetID`

.OUTPUTS
`Boolean ($true or $false)`

.Example
The following is an example on how to use the `Test-AssetID` function:


Test-AssetID -AssetID "PRE012345"


.NOTES
The `Test-AssetID` function is equipped with advanced function capabilities such as error handling and validates the 'ShouldProcess' parameter, enhancing its functionality.

#>
function Test-AssetID {
	# Set the CmdletBinding attribute and define the SupportsShouldProcess parameter
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		# Define the AssetID parameter. Its value can be passed in from the pipeline.
		[Parameter(Mandatory,ValueFromPipeline)]
		[string]$AssetID,

		# Define the AssetIDPrefix parameter. The default value is obtained from the device deployment default configuration.
		[Parameter()]
		[string]$AssetIDPrefix = $DeviceDeploymentDefaultConfig.AssetID.AssetIDPrefix,

		# Define the AssetIDLength parameter. The default value is obtained from the device deployment default configuration.
		[Parameter()]
		[int]$AssetIDLength = $DeviceDeploymentDefaultConfig.AssetID.AssetIDLength
	)

	# Create an empty array to keep track of errors
	begin {
		$errorList = @()
	}
	process {
		try {
			# Run the function and check if it should proceed (taking into consideration the use of -WhatIf or -Confirm parameters)
			if ($PSCmdlet.ShouldProcess("Testing Asset ID $AssetID")) {
				# If the length of the asset ID does not match the specified length, return $false
				if ($AssetID.Length -ne $AssetIDLength) {
					return $false
				}

				# If the asset ID does not start with the specified prefix, return $false
				if ($AssetID -notlike "$AssetIDPrefix*") {
					return $false
				}

				# If both conditions have been satisfied, return $true
				return $true
			}
		}
		catch {
			# Catch any errors and add them to the error list
			$errorList += $_
			Write-Error $_
		}
	}
	# At the end of the function, check if there were any errors. If there are, write them to the error stream and halt the script.
	end {
		if ($errorList.count -ne 0) {
			Write-Error "Error(s) in $($MyInvocation.MyCommand.Name):`n$($errorList | ForEach-Object {"$_`n"})`n $(Get-PSCallStack)" -ErrorAction Stop
		}
	}
}
