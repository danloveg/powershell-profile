# Common utilities
# Author: Daniel Lovegrove

Import-Module Alias

Function Edit-Profile {
    code "C:\Users\dlove\Google Drive\PowerShell\"
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

Function Set-LocationLink($target) {
    if($target.EndsWith(".lnk"))
    {
        $sh = new-object -com wscript.shell
        $fullpath = resolve-path $target
        $targetpath = $sh.CreateShortcut($fullpath).TargetPath
        set-location $targetpath
    }
    else {
        set-location $target
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

Function Repair-Emulators {
    # Removing .img files for Android emulators seems to make them work again
    Get-ChildItem "C:\Users\dlove\.android\avd\*\*.img" | Remove-Item
}

Function Repair-Nexus7 {
    Remove-Item "C:\Users\dlove\.android\avd\Nexus_7_API_25.avd\*.img"
}

Function Repair-Pixel {
    Remove-Item "C:\Users\dlove\.android\avd\Pixel_API_26_V3.avd\*.img"
}

Export-ModuleMember -Function @(
    "Edit-Profile",
    "Edit-Vimrc",
    "Get-MainProcesses",
    "Get-DiskUsage",
    "Touch",
    "Set-LocationLink",
    "Test-Administrator",
    "Repair-Emulators",
    "Repair-Nexus7",
    "Repair-Pixel"
)
