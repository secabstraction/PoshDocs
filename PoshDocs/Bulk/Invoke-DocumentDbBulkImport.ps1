function Invoke-DocumentDbBulkImport {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [CmdletBinding()]
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
        
        [Parameter(ParameterSetName='Partitioned')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${PartitionKey},
        
        [Parameter(ParameterSetName='Partitioned')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${PartitionKeyPath},
        
        [Parameter(ParameterSetName='Partitioned')]
        [ValidateRange(10001,250000)]
        [int]
        ${Throughput},
        
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
    
    $CommonParameters = @{}
    $LocalParameters = @('InputObject','Database','Collection','PartitionKey','PartitionKeyPath','Throughput')

    foreach ($Key in $PSBoundParameters.Keys) { # clone common parameters
        if ($Key -notin $LocalParameters) { $CommonParameters[$Key] = $PSBoundParameters[$Key] }
    }

    $BulkImport = @{
        Procedure = 'bulkImport'
        Parameters = @(,$InputObject)
        Link = 'dbs/{0}/colls/{1}/sprocs' -f $Database, $Collection
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'ProcedureError'
    }

    if ($PSBoundParameters['PartitionKey']) { $BulkImport['PartitionKey'] = $PartitionKey }
    
    $null = Invoke-DocumentDbProcedure @BulkImport @CommonParameters

    if ($ProcedureError.Count) {
        
        $Response = $ProcedureError[0].InnerException.Response

        switch ($Response.StatusCode.value__) {
            404 { # Not Found
                $ProcedureError.Clear()
                
                $Configuration = @{ Database = $Database; Collection = $Collection }
                if ($PSBoundParameters['PartitionKeyPath']) { $Configuration['PartitionKeyPath'] = $PartitionKeyPath }
                if ($PSBoundParameters['Throughput']) { $Configuration['Throughput'] = $Throughput }

                Initialize-DocumentDbBulkImport @Configuration @CommonParameters
                $null = Invoke-DocumentDbProcedure @BulkImport @CommonParameters

                if ($ProcedureError.Count) { throw $ProcedureError }
            }
            429 { # Too many requests
                $ProcedureError.Clear()
                
                $RetryAfter = $Response.Headers.Get('x-ms-retry-after-ms')

                Write-Warning ('Server received too many requests, sleeping for {0}ms...' -f $RetryAfter)
                Start-Sleep -Milliseconds $RetryAfter

                $null = Invoke-DocumentDbProcedure @BulkImport @CommonParameters
            }
            default { throw $ProcedureError }
        }
    }
}