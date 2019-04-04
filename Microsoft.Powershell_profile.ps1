# Powershell Profile
# Author: Daniel Lovegrove

Import-Module Alias
Import-Module Utilities
Import-Module MyPowershellGit
Import-Module WebServer

If (Test-Administrator) {
    $Host.UI.RawUI.ForegroundColor = "Red"
}
