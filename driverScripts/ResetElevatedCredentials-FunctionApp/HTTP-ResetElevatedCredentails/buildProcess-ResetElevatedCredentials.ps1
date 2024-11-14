# ----------------------------------------- General Setup ----------------------------------------- #
using namespace System.Net
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Set-StrictMode -Version 2.0

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"
# Connect to Azure
Connect-AzAccount

# ---------------------------------------- Global Defines ---------------------------------------- #
$userId = "MattTest@tricarecomau.onmicrosoft.com"
$vaultName = "tc-ae-d-devicebuild-kv"
$secretName = "ElevatedCredentialPassword"

# --------------------------------------- Function Defines --------------------------------------- #
function New-Password {
    param (
        [int]$Length = 16 # Default length of 16 characters
    )

    # Define character sets for password
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $numbers = '0123456789'
    $specialChars = '!@#$%^&*()-_=+[]{};:,.<>?'

    # Ensure we use at least one of each type for complexity
    $password = ""
    $password += $uppercase | Get-Random -Count 1
    $password += $lowercase | Get-Random -Count 1
    $password += $numbers | Get-Random -Count 1
    $password += $specialChars | Get-Random -Count 1

    # Generate remaining characters randomly from all sets
    $allChars = ($uppercase + $lowercase + $numbers + $specialChars) -split ''
    for ($i = 4; $i -lt $Length; $i++) {
        $password += $allChars | Get-Random -Count 1
    }

    # Shuffle the characters for added entropy
    $password = ($password.ToCharArray() | Get-Random -Count $password.Length) -join ''
    return $password
}

# --------------------------------------------- Main --------------------------------------------- #
try {
    $password = "$(New-Password)"
    # build the body object required for password reset
    $body = @{
        passwordProfile = @{
            forceChangePasswordNextSignIn = $false
            password = $password
        }
    }

    # Reset the user's password
    Update-MgUser -UserId $userId -BodyParameter $body -errorACtion Stop
    $output = "Password reset successfully for user: $userId"
    
    # Update Password in KV
    Set-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue (ConvertTo-SecureString -String $password -AsPlainText -Force)

    Write-Host $output
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $output
    })
} catch {
    $output = "Error resetting password: $_"
    Write-Error $output -ErrorAction "Continue"

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Body = $output
    })
}