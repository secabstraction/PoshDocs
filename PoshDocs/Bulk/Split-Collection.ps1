function Split-Collection {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Collections.ICollection]
        ${InputObject},

        [Parameter(Mandatory=$true)]
        [int]
        ${NewSize}
    )
    begin { $PSObjects = New-Object 'System.Collections.Generic.List[psobject]' }
    process {
        foreach ($Object in $InputObject) { 
            $PSObjects.Add($Object)
            if ($PSObjects.Count -eq $NewSize) { 
                ,[System.Collections.Generic.List[psobject]]$PSObjects.ToArray()
                $PSObjects.Clear()
            }
        }
    }
    end { ,[System.Collections.Generic.List[psobject]]$PSObjects.ToArray() }
}