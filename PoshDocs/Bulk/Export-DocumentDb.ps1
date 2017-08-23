function Export-DocumentDb {
    <#
        .SYNOPSIS
        Creates a JSON representation of object(s) and exports them to an Azure Cosmos DB DocumentDB instance.
        
        .DESCRIPTION
        Export-DocumentDb creates a JSON representation of object(s) and exports them to an Azure Cosmos DB DocumentDB instance.
        
        .PARAMETER InputObject
        Specifies the object(s) to export.
        
        .PARAMETER Database
        Specifies the DocumentDB database to export object(s) to.
        
        .PARAMETER Collection
        Specifies the DocumentDB collection to export object(s) to.
        
        .PARAMETER Size
        Specifies the number of objects to export per request, the default size is 100.
        
        .PARAMETER Uri
        Specifies the Uri of an Azure Cosmos DB DocumentDB instance. Defaults to Azure Cosmos DB emulator running on localhost.
        
        .PARAMETER ApiVersion
        Specifies the version of the DocumentDB's REST API.
        
        .PARAMETER Credential
        Specifies the key to use for accessing the DocumentDB instance.
        
        .EXAMPLE
        $Key = Get-Credential master
        Get-PSProcess | Export-DocumentDb -Database powersweep -Collection procs -Credential $Key -Uri https://powerstash.documents.azure.com
        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [psobject[]]
        ${InputObject},

        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database} = 'powerstash',
        
        [Parameter(Mandatory=$true, Position=1)]
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
        [string]
        ${TimeProperty},
        
        [ValidateNotNullOrEmpty()]
        [int]
        ${Size} = 100,
        
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

    begin { 
        $Time = [datetime]::Now
        $Collection = [regex]::Replace($Collection, '^Deserialized.', '').ToLower() 
        
        # We need to group objects by time before exporting
        # Create a dictionary of lists with time as the key
        $ObjectDictionary = New-Object 'System.Collections.Generic.Dictionary[string,Object]'
    }
    
    process { 
        foreach ($Object in $InputObject) { 
            
            if ($PSBoundParameters['TimeProperty']) { $Time = [datetime]::Parse($Object.$TimeProperty) }
            elseif ($Object.SweepTime) { $Time = [datetime]::Parse($Object.SweepTime) }

            $Index = $Database + '-' + $Time.ToUniversalTime().ToString('yyyy.MM.dd')
            
            # Add the object to an existing list
            if ($ObjectDictionary.ContainsKey($Index)) { ($ObjectDictionary[$Index]).Add($Object) }
            
            else { # Add the object to a new list in the dictionary
                $ObjectList = New-Object 'System.Collections.Generic.List[psobject]'
                $ObjectList.Add($Object)
                $ObjectDictionary[$Index] = $ObjectList
            }
        } 
    }

    end { 
        $CommonParameters = @{}
        
        $PSBoundParameters.Keys | ForEach-Object { # clone common parameters
            if ($_ -notin @('InputObject','TimeProperty','Database','Size')) { $CommonParameters[$_] = $PSBoundParameters[$_] }
        }
        
        $ObjectDictionary.Keys | ForEach-Object {

            if (($ObjectDictionary[$_]).Count -le $Size) {
                
                $ImportParameters = @{
                    Database = $_ 
                    InputObject = $ObjectDictionary[$_]
                }

                Invoke-DocumentDbBulkImport @ImportParameters @CommonParameters
            }

            else {

                $Database = $_

                Split-Collection -InputObject $ObjectDictionary[$_] -NewSize $Size | ForEach-Object {
                    
                    $ImportParameters = @{
                        Database = $Database
                        InputObject = $_
                    }
    
                    Invoke-DocumentDbBulkImport @ImportParameters @CommonParameters
                }
            }
        }       
    }
}