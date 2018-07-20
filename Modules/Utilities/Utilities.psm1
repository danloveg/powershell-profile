# Common utilities
# Author: Daniel Lovegrove

Import-Module Alias

Function Edit-Profile {
    vim $Profile
}

Function Edit-Vimrc {
    vim $HOME\_vimrc
}

Function Get-MainProcesses {
    Get-Process | Where-Object {$_.MainWindowTitle} | Format-Table Id, Name, MainWindowTitle -autosize
}

Function Get-DiskUsage($dir=".") {
    Get-ChildItem $dir | ForEach-Object {
        $FirstItem = $_;
        Get-ChildItem -Recurse $_.FullName |
        Measure-Object -Property Length -Sum |
        Select-Object @{Name="Name";Expression={$FirstItem}}, Sum
    }
}

# Credit to staxmanade/DevMachineSetup
Function Touch($FilePath) {
    If(Test-Path $FilePath) {
        $File = Get-Item $FilePath;
        $Now = Get-Date
        $File.LastWriteTime = $Now
    }
    Else
    {
        "" | Out-File -FilePath $FilePath -Encoding ASCII
    }
}

# Copied from dahlbyk/posh-git
Function Test-Administrator {
    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        $currentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    return 0 -eq (id -u)
}

Export-ModuleMember -Function @(
    "Edit-Profile",
    "Edit-Vimrc",
    "Get-MainProcesses",
    "Get-DiskUsage",
    "Touch",
    "Test-Administrator"
)
