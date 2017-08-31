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
        ${Throughput} = 50000,
        
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
    
    $PSBoundParameters.Keys | ForEach-Object { # clone common parameters
        if ($_ -notin @('Database','Collection')) { $CommonParameters[$_] = $PSBoundParameters[$_] }
    }
    
    $CommonParameters['ErrorAction'] = 'SilentlyContinue'
    $CommonParameters['ErrorVariable'] = 'ResourceError'
    
    # Check for collection
    $CollectionLink = 'dbs/{0}/colls/{1}' -f $Database, $Collection
    $null = Get-DocumentDbResource -Link $CollectionLink @CommonParameters
    
    if ($ResourceError.Count) { # Create if not found

        $Response = $ResourceError[0].InnerException.Response

        if ($Response.StatusCode -eq 'NotFound') {

            $ResourceError.Clear()

            # Check for database
            $DatabaseLink = "dbs/$Database"
            $null = Get-DocumentDbResource -Link $DatabaseLink @CommonParameters
            
            if ($ResourceError.Count) { # Create if not found
                
                $Response = $ResourceError[0].InnerException.Response
                
                if ($Response.StatusCode -eq 'NotFound') {
                    
                    $ResourceError.Clear()
                    
                    $Resource = @{
                        Type = 'dbs'
                        Body = '{{"id":"{0}"}}' -f $Database
                    }
                    
                    $null = New-DocumentDbResource @Resource @CommonParameters
        
                    if ($ResourceError.Count) { throw $ResourceError }
                }
                else { throw $ResourceError }
            }

            $Resource = @{
                Type = 'colls'
                Link = $DatabaseLink
                Headers = @{ 'x-ms-offer-throughput' = $Throughput }
            }

            $Body = @{ 
                id = $Collection
                indexingPolicy = @{
                    automatic = $true
                    indexingMode = 'Lazy' # supposed to increase throughput, can change later
                }
                partitionKey = @{ 
                    paths = @("/$PartitionKeyPath")  
                    kind = 'Hash'
                }
            }

            $Resource['Body'] = ConvertTo-Json $Body -Compress

            $null = New-DocumentDbResource @Resource @CommonParameters

            if ($ResourceError.Count) { throw $ResourceError }
        }
        else { throw $ResourceError }
    }

    # Create bulkImport stored procedure, here-string is portable
    $Procedure = @'
function bulkImport(transactionId, docs) {
    var collection = getContext().getCollection();
    var collectionLink = collection.getSelfLink();

    var count = 0;

    if (!docs) throw new Error("The array is undefined or null.");
    if (!transactionId) throw new Error("The transactionId is undefined or null.")

    var docsLength = docs.length;
    
    if (docsLength == 0) {
        getContext().getResponse().setBody(0);
        return;
    }

    tryCreateDoc(docs[count], tryCreateNextDoc);

    function tryCreateDoc(doc, callback) {
        doc.transactionId = transactionId;
        var isAccepted = collection.createDocument(collectionLink, doc, tryCreateNextDoc);
        if (!isAccepted) getContext().getResponse().setBody(count);
    }

    function tryCreateNextDoc(err, doc, options) {
        if (err) throw err;

        count++;

        if (count >= docsLength) {
            getContext().getResponse().setBody(count);
        } else {
            tryCreateDoc(docs[count], tryCreateNextDoc);
        }
    }
}
'@
    
    $Resource = @{
        Type = 'sprocs'
        Link = $CollectionLink
        Body = ConvertTo-Json @{ id = 'bulkImport'; body = $Procedure } -Compress
    }
    
    $null = New-DocumentDbResource @Resource @CommonParameters
    
    if ($ResourceError.Count) { throw $ResourceError }
}