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
        [System.Collections.Generic.List[psobject]]
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
        [ValidateRange(10001,250000)]
        [int]
        ${Throughput},
        
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApiVersion},
        
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential}
    )
    
    $CommonParameters = @{}

    $PSBoundParameters.Keys | ForEach-Object { # clone common parameters
        if ($_ -notin @('InputObject','Database','Collection','PartitionKey','Throughput')) { $CommonParameters[$_] = $PSBoundParameters[$_] }
    }
    
    $CommonParameters['Link'] = 'dbs/{0}/colls/{1}/sprocs' -f $Database, $Collection
    $CommonParameters['ErrorAction'] = 'SilentlyContinue'
    $CommonParameters['ErrorVariable'] = 'ProcedureError'

    $TransactionId = [guid]::NewGuid()

    $BulkImport = @{
        Procedure = 'bulkImport'
        Parameters = @($TransactionId, $InputObject)
    }

    if ($PSBoundParameters['PartitionKey']) { $BulkImport['PartitionKey'] = $PartitionKey }
    
    Invoke-DocumentDbProcedure @BulkImport @CommonParameters

    if ($ProcedureError.Count) {
        
        $Response = $ProcedureError[0].InnerException.Response

        switch ($Response.StatusCode.value__) {
            404 { # Not Found
                $ProcedureError.Clear()
    
                $InitParameters = $CommonParameters.Clone()
                $InitParameters['Collection'] = $Collection
                $InitParameters['Database'] = $Database
                $InitParameters.Remove('Link')
                
                Initialize-DocumentDbBulkImport @InitParameters
    
                $Response = Invoke-DocumentDbProcedure @BulkImport @CommonParameters
            }
            429 { # Too many requests
                $ProcedureError.Clear()
                
                $RetryAfter = $Response.Headers.Get('x-ms-retry-after-ms')

                Write-Warning ('Server received too many requests, sleeping for {0}ms...' -f $RetryAfter)
                Start-Sleep -Milliseconds $RetryAfter

                Invoke-DocumentDbProcedure @BulkImport @CommonParameters
            }
            default { throw $ProcedureError }
        }
    }
}