# Common utilities
# Author: Daniel Lovegrove

Import-Module Alias

Function Get-MainProcesses {
    Get-Process | Where-Object {$_.MainWindowTitle} | Format-Table Id, Name, MainWindowTitle -autosize
}

Function Get-FileSize($File) {
    $Size = (Get-Item $File).Length
    [PsCustomObject] @{Sum=$Size}
}

Function Get-FolderSize($Folder) {
    $Files = Get-ChildItem -Path $Folder -File -Recurse
    If (-Not($Files)) {
        [PsCustomObject] @{Sum=0}
    }
    Else {
        $Size = 0
        ForEach ($File in $Files) {
            $Size += (Get-FileSize $File).Sum
        }
        [PsCustomObject] @{Sum=$Size}
    }
}

Function Get-DiskUsage {
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateScript({
            If (-Not (Test-Path -Path $_ -ErrorAction SilentlyContinue)) {
                throw "Target `"$_`" does not exist"
            }
            Else {
                return $True
            }
        })]
        [String]
        $Target
    )

    If (Test-Path -Path $Target -PathType Container -ErrorAction SilentlyContinue) {
        $TopLevelItems = Get-ChildItem $Target

        ForEach ($Item in $TopLevelItems) {
            If (Test-Path -Path $Item -PathType Leaf -ErrorAction SilentlyContinue) {
                Get-FileSize $Item |
                Select-Object Sum, @{Name='Name';Expression={$Item.Name}} |
                ConvertTo-HumanReadableSize
            }
            Else {
                Get-FolderSize $Item |
                Select-Object Sum, @{Name='Name';Expression={$Item.Name}} |
                ConvertTo-HumanReadableSize
            }
        }
    }
    Else {
        $TargetItem = Get-Item $Target
        Get-FileSize $TargetItem |
        Select-Object Sum, @{Name='Name';Expression={$TargetItem.Name}} |
        ConvertTo-HumanReadableSize
    }
}

Function ConvertTo-HumanReadableSize {
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [Object[]] $diskUsages
    )

    BEGIN {}

    PROCESS {
        ForEach ($usage in $diskUsages) {
            $bytes = $usage.Sum
            $kilobytes = $bytes / 1kb
            $megabytes = $bytes / 1mb
            $gigabytes = $bytes / 1gb

            $humanReadableSize = ""

            If ($kilobytes -lt 1) {
                $humanReadableSize = ("{0}.00  B" -f $bytes).PadLeft(10)
            }
            ElseIf ($megabytes -lt 1) {
                $humanReadableSize = ("{0:N2} KB" -f $kilobytes).PadLeft(10)
            }
            ElseIf ($gigabytes -lt 1) {
                $humanReadableSize = ("{0:N2} MB" -f $megabytes).PadLeft(10)
            }
            Else {
                $humanReadableSize = ("{0:N2} GB" -f $gigabytes).PadLeft(10)
            }

            [PsCustomObject]@{'Name' = $usage.Name; 'FileSize' = $humanReadableSize}
        }
    }

    END {}
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

Export-ModuleMember -Function @(
    "Get-MainProcesses",
    "Get-DiskUsage",
    "Touch",
    "Set-LocationLink",
    "Test-Administrator"
)
