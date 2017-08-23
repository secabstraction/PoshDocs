function Initialize-DocumentDbBulkImport {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    param (
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
        ${PartitionKeyPath} = 'ComputerName',
        
        [Parameter(ParameterSetName='Partitioned')]
        [ValidateRange(10001,250000)]
        [int]
        ${Throughput} = 25000,
        
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
        if ($_ -notin @('Database','Collection')) { $CommonParameters[$_] = $PSBoundParameters[$_] }
    }
    
    $CommonParameters['ErrorAction'] = 'SilentlyContinue'
    $CommonParameters['ErrorVariable'] = 'ResourceError'
    
    # Check for collection
    $CollectionLink = 'dbs/{0}/colls/{1}' -f $Database, $Collection
    $null = Get-DocumentDbResource -Link $CollectionLink @CommonParameters
    
    if ($ResourceError.Count) { # Create if not found
        if ($ResourceError[0].InnerException.Response.StatusCode -eq 'NotFound') {

            $ResourceError.Clear()

            # Check for database
            $DatabaseLink = "dbs/$Database"
            $null = Get-DocumentDbResource -Link $DatabaseLink @CommonParameters
            
            if ($ResourceError.Count) { # Create if not found
                if ($ResourceError[0].InnerException.Response.StatusCode -eq 'NotFound') {
                    
                    $ResourceError.Clear()
                    
                    $Resource = @{
                        Type = 'dbs'
                        Body = '{{"id":"{0}"}}' -f $Database
                    }
                    
                    $null = New-DocumentDbResource @Resource @CommonParameters
        
                    if ($ResourceError.Count) { throw $ResourceError[0] }
                }
                else { throw $ResourceError[0] }
            }

            $Resource = @{
                Type = 'colls'
                Link = $DatabaseLink
                Headers = @{ 'x-ms-offer-throughput' = $Throughput }
            }

            $Body = @{ 
                id = $Collection
                partitionKey = @{ 
                    paths = @("/$PartitionKeyPath")  
                    kind = 'Hash'
                }
            }

            $Resource['Body'] = ConvertTo-Json $Body -Compress

            $null = New-DocumentDbResource @Resource @CommonParameters

            if ($ResourceError.Count) { throw $ResourceError[0] }
        }
        else { throw $ResourceError[0] }
    }

    # Create bulkImport stored procedure
    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'StoredProcedures'
    $ScriptPath = Join-Path -Path $ScriptPath -ChildPath 'bulkImport.js'
    $Procedure = [System.IO.File]::ReadAllText($ScriptPath)
    
    $Resource = @{
        Type = 'sprocs'
        Link = $CollectionLink
        Body = ConvertTo-Json @{
            id = 'bulkImport'
            body = $Procedure
        } -Compress
    }
    
    $null = New-DocumentDbResource @Resource @CommonParameters
    
    if ($ResourceError.Count) { throw $ResourceError[0] }
}