<#
    .SYNOPSIS
    Initializes resources of a Document DB collection to support server-side bulkimport of documents.

    .DESCRIPTION
    Initialize-DocumentDbBulkImport checks for necessary resources to support server-side bulkimport of JSON documents into a Document DB collection and creates any resources that aren't present and initialized.

    .PARAMETER Database
    Specifies the database name for the collection.

    .PARAMETER Collection
    Specifies the collection name.

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

    .NOTES
    Author: Jesse Davis (@secabstraction)
    License: BSD 3-Clause

    .LINK
    https://github.com/Azure/azure-documentdb-js-server
#>
function Initialize-DocumentDbBulkImport {
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
        [ValidateRange(1000,250000)]
        [int]
        ${Throughput} = 50000,
        
        [int]
        ${TimeToLive} = -1,
        
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
    
    switch -regex ($PSBoundParameters.Key) {
        'Database|Collection|PartitionKeyPath|Throughput|TimeToLive' {
            $null = $PSBoundParameters.Remove($_) # used in this script only
        }
    }
    
    $PSBoundParameters['ErrorAction'] = 'SilentlyContinue'
    $PSBoundParameters['ErrorVariable'] = 'ResourceError'
    
    # Check for collection
    $CollectionLink = 'dbs/{0}/colls/{1}' -f $Database, $Collection
    $null = Get-DocumentDbResource -Link $CollectionLink @PSBoundParameters    
    if ($ResourceError.Count) {

        if ($ResourceError[0].InnerException.Response.StatusCode -ne 'NotFound') { 
            throw $ResourceError
        } else { # Create collection, but check for database first
            $ResourceError.Clear()
            $null = Get-DocumentDbResource -Link "dbs/$Database" @PSBoundParameters            
            if ($ResourceError.Count) {

                if ($ResourceError[0].InnerException.Response.StatusCode -ne 'NotFound') {
                    throw $ResourceError
                } else { # Create database
                    $ResourceError.Clear()                    
                    $Resource = @{
                        Type = 'dbs'
                        Body = '{{"id":"{0}"}}' -f $Database
                    }
                    
                    $null = New-DocumentDbResource @Resource @PSBoundParameters
                    if ($ResourceError.Count) { 
                        throw $ResourceError
                    }
                }  
            }

            $Resource = @{
                Type = 'colls'
                Link = "dbs/$Database"
                Headers = @{ 'x-ms-offer-throughput' = $Throughput }
                Body = ConvertTo-Json -Compress -InputObject @{ 
                    id = $Collection
                    indexingPolicy = @{
                        automatic = $true
                        indexingMode = 'Lazy' # should increase throughput
                    }
                    partitionKey = @{
                        paths = @("/$PartitionKeyPath")
                        kind = 'Hash'
                    }
                    defaultTtl = $TimeToLive
                }
            }

            $null = New-DocumentDbResource @Resource @PSBoundParameters
            if ($ResourceError.Count) {
                throw $ResourceError
            }
        }
    }

    # bulkImport stored procedure, here-string is portable
    # https://github.com/Azure/azure-documentdb-js-server/blob/master/samples/stored-procedures/BulkImport.js
    $Procedure = @'
function bulkImport(docs) {
    var count = 0;
    var collection = getContext().getCollection();
    var collectionLink = collection.getSelfLink();

    if (!docs) throw new Error("The array is undefined or null.");

    var docsLength = docs.length;
    
    if (docsLength == 0) {
        getContext().getResponse().setBody(0);
        return;
    }

    tryCreateDoc(docs[count], tryCreateNextDoc);

    function tryCreateDoc(doc, callback) {
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
        Body = ConvertTo-Json -Compress -InputObject @{
            id = 'bulkImport'
            body = $Procedure
        }
    }

    $null = New-DocumentDbResource @Resource @PSBoundParameters    
    if ($ResourceError.Count) {
        throw $ResourceError
    }
}