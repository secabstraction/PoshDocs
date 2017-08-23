Get-ChildItem $PSScriptRoot -Recurse | 
    Where-Object { $_.Extension -eq '.ps1' } | 
        ForEach-Object { . $_.FullName }