function Split-Collection {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [psobject[]]
        ${InputObject},

        [Parameter(Mandatory=$true)]
        [int]
        ${NewSize}
    )
    begin { $PSObjects = New-Object 'System.Collections.Generic.List[psobject]' }
    process {
        foreach ($Object in $InputObject) { 
            if ($PSObjects.Count -eq $NewSize) { ,$PSObjects; $PSObjects.Clear() }
            else { $null = $PSObjects.Add($Object) }
        }
    }
    end { if ($PSObjects.Count) { ,$PSObjects } }
}