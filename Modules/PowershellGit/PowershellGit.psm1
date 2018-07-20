# Imports posh-git and edits the settings for it

[Bool] $PoshGitImported = $False

If (-Not(Get-Module -ListAvailable -Name posh-git)) {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    If ((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        PowershellGet\Install-Module posh-git -Scope CurrentUser -Force
        Import-Module posh-git
        $PoshGitImported = $True
    } Else {
        Write-Host "Must run as administrator to install posh-git."
    }
} Else {
    Import-Module posh-git
    $PoshGitImported = $True
}

# Avoids displaying unsupported symbols in command line prompt
If ($PoshGitImported) {
    $GitPromptSettings.BranchIdenticalStatusToSymbol = "=="
    $GitPromptSettings.BranchAheadStatusSymbol = "ahead:"
    $GitPromptSettings.BranchBehindStatusSymbol = "behind:"
}
