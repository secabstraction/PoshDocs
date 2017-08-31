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
        
        .PARAMETER Version
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
        ${Database} = 'poshdoc',
        
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
        ${Version},
        
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential}
    )

    begin { 
        $Date = [datetime]::UtcNow
        
        # We need to group objects by time before exporting
        # Create a dictionary of lists with time as the key
        $Dictionary = New-Object 'System.Collections.Generic.Dictionary[string,System.Collections.ObjectModel.Collection[psobject]]'
    }
    
    process { 
        foreach ($Object in $InputObject) { 
            
            if ($PSBoundParameters['TimeProperty']) { $Date = [datetime]::Parse($Object.$TimeProperty).ToUniversalTime() }

            $Index = '{0}-{1}' -f $Database, $Date.ToString('yyyy.MM.dd')
            
            # Add the object to an existing list
            if (!$Dictionary.ContainsKey($Index)) { $Dictionary[$Index] = New-Object 'System.Collections.ObjectModel.Collection[psobject]' }
            ($Dictionary[$Index]).Add($Object)
        } 
    }

    end { 
        $BulkParameters = @{}
        
        $PSBoundParameters.Keys | ForEach-Object { # clone common parameters
            if ($_ -notin @('InputObject','TimeProperty','Database','Size')) { $BulkParameters[$_] = $PSBoundParameters[$_] }
        }
        
        $Dictionary.Keys | ForEach-Object {

            if (($Dictionary[$_]).Count -le $Size) {
                
                $BulkParameters['Database'] = $_
                $BulkParameters['InputObject'] = $Dictionary[$_]

                Invoke-DocumentDbBulkImport @BulkParameters
            }

            else {

                $Index = $_

                Split-Collection -InputObject $Dictionary[$Index] -NewSize $Size | ForEach-Object {
                    
                    $BulkParameters['Database'] = $Index
                    $BulkParameters['InputObject'] = $_
    
                    Invoke-DocumentDbBulkImport @BulkParameters
                }
            }
        }       
    }
}