<#
    .SYNOPSIS
    Resizes collecitons of arbitrary psobjects.

    .DESCRIPTION
    Split-Collection is a simple helper function to resize large collections into smaller sets.

    .PARAMETER InputObject
    Specifies the collection to resize.

    .PARAMETER NewSize
    Specifies the count of objects to be returned in resized collections.
    The final collection returned will contain remainder of objects.

    .EXAMPLE
    Split-Collection @(1,2,3,4) -NewSize 2

    .NOTES
    Author: Jesse Davis (@secabstraction)
    License: BSD 3-Clause
#>
function Split-Collection {
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [psobject[]]
        ${InputObject},

        [Parameter(Mandatory=$true)]
        [int]
        ${NewSize}
    )
    begin {
        $PSObjects = New-Object 'System.Collections.Generic.List[psobject]'
    } process {
        foreach ($Object in $InputObject) {
            $PSObjects.Add($Object)
            if ($PSObjects.Count -eq $NewSize) { 
                ,$PSObjects
                $PSObjects.Clear()
            }
        }
    } end { 
        if ($PSObjects.Count) { 
            ,$PSObjects
        }
    }
}