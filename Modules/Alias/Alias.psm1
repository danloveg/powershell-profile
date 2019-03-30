# Common Aliases
# Author: Daniel Lovegrove

Set-Alias vim "C:\Program Files (x86)\Vim\vim81\vim.exe"
Set-Alias notepad++ "C:\Program Files (x86)\Notepad++\notepad++.exe"
Set-Alias 7z "C:\Program Files\7-Zip\7z.exe"
Set-Alias Typora "C:\Program Files\Typora\Typora.exe"
Set-Alias Follow-Link Set-LocationLink

Export-ModuleMember -Alias @(
    "vim",
    "notepad++",
    "7z",
    "Typora",
    "Follow-Link"
)
