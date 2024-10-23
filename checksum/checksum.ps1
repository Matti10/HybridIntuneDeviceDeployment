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
        [string]$checksumPath = ".\checksum\checksum.txt",
        
        [Parameter()]
        [string]$rootPath = ".\",

        [Parameter()]
        [switch]$noFileOutput
    )

    # Get all files in the specified directory and its subdirectories, sorted by full name
    $files = Get-ChildItem -Recurse -File -Path $rootPath | Sort-Object FullName
    
    # Generate checksums for each file and store them in an array
    $checksums = foreach ($file in $files) {
        # Compute the MD5 hash for the current file
        $hash = Get-FileHash -Path $file.FullName -Algorithm MD5
        # Format the checksum and file path as a string
        "$($hash.Hash)  $($file.FullName)"
    }
    
    # Combine all individual checksums into a single string and compute a final checksum
    $stringAsStream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stringAsStream)
    $writer.write($checksums)
    $writer.Flush()
    $stringAsStream.Position = 0

    $finalChecksum = (Get-FileHash -InputStream $stringAsStream).Hash
    Write-Host "Checksum for repo: $($finalChecksum)"
    
    if (-not $noFileOutput) {
        # Save the final checksum to the specified file path
        $finalChecksum | Out-File -FilePath $checksumPath
        Write-Host "Checksum for commit generated and saved to $checksumPath."
    }

    return $finalChecksum
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
        [string]$checksumPath = ".\checksum\checksum.txt",

        [Parameter()]
        [string]$rootPath = ".\"
    )

    # Read the remote checksum from the specified file
    $remoteChecksum = Get-Content -Path $checksumPath
    
    # Generate the local checksum for the current files
    $localChecksum = Build-CheckSum -checksumPath $checksumPath -rootPath $rootPath -noFileOutput

    # Compare the remote checksum with the locally generated checksum
    if ($remoteChecksum -ne $localChecksum) {
        Write-Error "Checksum validation has failed on this repo." -ErrorAction:$ErrorActionPreference
        return $false
    } else {
        Write-Verbose "Checksum validation successful."
        return $true
    }
}
