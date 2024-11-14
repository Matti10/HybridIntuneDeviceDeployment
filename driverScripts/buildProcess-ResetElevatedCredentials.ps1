# Install Microsoft Graph PowerShell SDK if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser
Disconnect-MgGraph
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Define user and new password
$userId = "MattTest@tricarecomau.onmicrosoft.com" # The user's ID or principal name (email)
$newPassword = "&&75&Often&Wheat&Chief&53&&" # The new password

# Reset the user's password
$body = @{
    passwordProfile = @{
        forceChangePasswordNextSignIn = $false
        password = $newPassword
    }
}

try {
    Update-MgUser -UserId $userId -BodyParameter $body -errorACtion Stop
    Write-Host "Password reset successfully for user: $userId"
} catch {
    Write-Host "Error resetting password: $_"
}
