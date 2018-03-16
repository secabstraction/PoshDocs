<#
    .SYNOPSIS
    Imports a collection of objects into a Document DB collection.

    .DESCRIPTION
    Invoke-DocumentDbBulkImport imports a collection of objects into a Document DB collection via a stored javascript procedure that accepts the collection of objects to be imported as a parameter.

    .PARAMETER InputObject
    Specifies a collection of objects to be imported into a collection.

    .PARAMETER Database
    Specifies the database name for the collection.

    .PARAMETER Collection
    Specifies the collection name.

    .PARAMETER PartitionKey
    Specifies the property used to partition data across a collection. References the PartitionKey for collections that already exist.

    .PARAMETER PartitionKeyPath
    Specifies the property to use as the key for partitioning data across a collection. Sets the PartitionKey value during collection creation.

    .PARAMETER Throughput
    Specifies the request units per second to reserve for the collection.

    .PARAMETER Uri
    Specifies the URI of the Document DB REST endpoint.

    .PARAMETER Version
    Specifies the version of the Document DB REST API.

    .PARAMETER Credential
    Specifies the credentials for accessing the Document DB REST endpoint.

    .EXAMPLE
    An example

    .NOTES
    Author: Jesse Davis (@secabstraction)
    License: BSD 3-Clause

    .LINK
    https://github.com/Azure/azure-documentdb-js-server/blob/master/samples/stored-procedures/BulkImport.js
#>
function Invoke-DocumentDbBulkImport {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.ObjectModel.Collection[psobject]]
        ${InputObject},

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database},
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Collection},
        
        [ValidateRange(1000,250000)]
        [int]
        ${Throughput},
        
        [int]
        ${TimeToLive},
        
        [Parameter(ParameterSetName='Partitioned')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${PartitionKey},
        
        [Parameter(ParameterSetName='Partitioned')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${PartitionKeyPath},
        
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Version},
        
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential}
    )

    $Configuration = @{}
    $DocumentDb = @{}
    $BulkImport = @{
        Procedure = 'bulkImport'
        Parameters = @(,$InputObject)
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'ProcedureError'
    }

    switch -regex ($PSBoundParameters.Keys) {
        'InputObject' {
            continue # used in this script only
        }
        'PartitionKeyPath|Throughput|TimeToLive' { 
            $Configuration[$_] = $PSBoundParameters[$_]
        }
        'PartitionKey' { 
            $BulkImport[$_] = $PSBoundParameters[$_]
        }
        default {
            $DocumentDb[$_] = $PSBoundParameters[$_]
        }
    }
    
    $null = Invoke-DocumentDbProcedure @BulkImport @DocumentDb

    if ($ProcedureError.Count) {        
        $Response = $ProcedureError[0].InnerException.Response
        switch ($Response.StatusCode.value__) {
            404 { # Not Found
                $ProcedureError.Clear()
                $null = Initialize-DocumentDbBulkImport @Configuration @DocumentDb
                $null = Invoke-DocumentDbProcedure @BulkImport @DocumentDb
                if ($ProcedureError.Count) { 
                    throw $ProcedureError
                }
            }
            429 { # Too many requests
                $ProcedureError.Clear()                
                $RetryAfter = $Response.Headers.Get('x-ms-retry-after-ms')
                Write-Warning ('Server received too many requests, sleeping for {0}ms...' -f $RetryAfter)
                Start-Sleep -Milliseconds $RetryAfter
                $null = Invoke-DocumentDbProcedure @BulkImport @DocumentDb
            }
            default { 
                throw $ProcedureError
            }
        }
    }
}