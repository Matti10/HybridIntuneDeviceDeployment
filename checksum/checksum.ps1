<#
.SYNOPSIS
    Generates and saves a checksum for all files in a specified directory.

.DESCRIPTION
    The Build-CheckSum function calculates a checksum for all files in the specified directory (including subdirectories) 
    and saves it to a specified file path. The checksum is generated using the MD5 algorithm.

.PARAMETER checksumPath
    The file path where the final checksum will be saved. 
    The default value is ".\checksum\checksum.txt".

.PARAMETER rootPath
    The root directory from which to start the checksum calculation. 
    The default value is the current directory ("./").

.EXAMPLE
    Build-CheckSum -checksumPath ".\myChecksums.txt" -rootPath "C:\MyRepo"
    This command will generate a checksum for all files in "C:\MyRepo" 
    and save it to "myChecksums.txt".
#>
function Build-CheckSum {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        [string]$checksumPath = "$((Get-Location).ProviderPath)\checksum\checksum.json",
        
        [Parameter()]
        [string]$rootPath = ((Get-Location).ProviderPath),

        [Parameter()]
        [switch]$noFileOutput
    )
    try {

        # Get all files in the specified directory and its subdirectories, sorted by full name
        $files = Get-ChildItem -Recurse -File -Path $rootPath | Where-Object { $_.FullName -like "*src*" -or $_.FullName -like "*.psm1*" } | Sort-Object FullName
        
        # Generate checksums for each file and store them in an array
        $checksums = foreach ($file in $files) {
            $stringAsStream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stringAsStream)
            $writer.write("$(Get-Content -Path $file.FullName)")
            $writer.Flush()
            $stringAsStream.Position = 0
            @{
                Hash = (Get-FileHash -InputStream $stringAsStream -Algorithm SHA1).hash
                Path = $file.fullname.replace($rootPath, "")
            }
        } 
    
        if (-not $noFileOutput) {
            # Save the final checksum to  the specified file path
            New-Item -Path $checksumPath -Force -value ($checksums | ConvertTo-Json) -Confirm:$false -ItemType File
            Write-Host "Checksum for commit generated and saved to $checksumPath."
        }
    
        return $checksums
    } catch {
        Get-PSCallStack
        Write-Error $_ -ErrorAction Stop
    }
}

<#
.SYNOPSIS
    Validates the checksum of files in a specified directory against a saved checksum file.

.DESCRIPTION
    The Test-CheckSum function compares the current checksum of files in the specified directory 
    with the checksum stored in a file. If they do not match, an error is raised.

.PARAMETER checksumPath
    The file path where the expected checksum is stored.
    The default value is ".\checksum\checksum.txt".

.PARAMETER rootPath
    The root directory from which to validate the checksum. 
    The default value is the current directory ("./").

.EXAMPLE
    Test-CheckSum -checksumPath ".\myChecksums.txt" -rootPath "C:\MyRepo"
    This command will validate the checksums of all files in "C:\MyRepo" 
    against those saved in "myChecksums.txt".
#>
function Test-CheckSum {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter()]
        [string]$checksumPath = "$((Get-Location).ProviderPath)\checksum\checksum.json",
        
        [Parameter()]
        [string]$rootPath = ((Get-Location).ProviderPath)
    )

    # Read the remote checksum from the specified file
    $remoteChecksum = Get-Content -Path $checksumPath | ConvertFrom-Json
    
    # Generate the local checksum for the current files
    $localChecksum = Build-CheckSum -checksumPath $checksumPath -rootPath $rootPath -noFileOutput

    # Compare the remote checksum with the locally generated checksum
    $valid = $true
    if ($remoteChecksum -ne $localChecksum) {
        foreach ($localFile in $localChecksum) {
            $remoteFile = $remoteChecksum | Where-Object { $_.Path -eq $localFile.Path }
            if ($null -eq $remoteFile -or $remoteFile.Hash -ne $localFile.Hash ) {
                Write-Error "Checksum validation has failed for $($localFile.Path)" -ErrorAction:$ErrorActionPreference
                $valid = $valid -and $false
            }
        }
    }

    if ($valid) {
        Write-Verbose "Checksum validation successful."
    }
    return $valid
}
