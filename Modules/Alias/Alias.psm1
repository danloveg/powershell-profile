# Common aliases
# Author: Daniel Lovegrove

Set-Alias vim "C:\Program Files (x86)\Vim\vim81\vim.exe"
Set-Alias notepad++ "C:\Program Files (x86)\Notepad++\notepad++.exe"
Set-Alias 7z "C:\Program Files\7-Zip\7z.exe"
Set-Alias Typora "C:\Program Files\Typora\Typora.exe"
Set-Alias sqlite3 "C:\Program Files\sqlite\sqlite3.exe"
Set-Alias Follow-Link Set-LocationLink
# Set-Alias wsdl "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\wsdl.exe"

Export-ModuleMember -Alias @(
    "vim",
    "notepad++",
    "7z",
    "Typora",
    "Follow-Link",
    "sqlite3"
)