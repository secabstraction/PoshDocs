<#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Link
    Specifies the path to a resource.

    .PARAMETER Type
    Specifies the type of resource.

    .PARAMETER PartitionKey
    Specifies a unique field to use as the partition key for sharding data across a collection.

    .PARAMETER Body
    Specifies the parameters from which the resource will be created.

    .PARAMETER Headers
    Specifies any custom headers to pass to the Azure Document DB REST API.

    .PARAMETER Method
    Specifies the WebRequestMethod to use for interacting with the Document DB REST API.

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
    https://docs.microsoft.com/en-us/rest/api/documentdb/common-tasks-using-the-documentdb-rest-api
#>
function Invoke-DocumentDbRestApi {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri} = 'https://localhost:8081',

        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        ${Method},
        
        [ValidateNotNullOrEmpty()]
        [Object]
        ${Body},
        
        [ValidateNotNullOrEmpty()]
        [hashtable]
        ${Headers},
        
        [ValidateSet('dbs','colls','docs','users','permissions','sprocs','triggers','udfs','attachments','offers')]
        [string]
        ${Type},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Link},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${PartitionKey},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Version} = '2017-11-15',

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )

    if ($PSBoundParameters.ContainsKey('Version')) {
        $null = $PSBoundParameters.Remove('Version')
    }
    if ($PSBoundParameters.ContainsKey('Headers')) { 
        $PSBoundParameters['Headers']['x-ms-version'] = $Version
    } else {
        $PSBoundParameters['Headers'] = @{ 'x-ms-version' = $Version }
    }
    if ($PSBoundParameters.ContainsKey('PartitionKey')) {
        $null = $PSBoundParameters.Remove('PartitionKey')
        $PSBoundParameters['Headers']['x-ms-documentdb-partitionkey'] = ConvertTo-Json $PartitionKey -Compress
    }
    
    $TokenParameters = @{ Link = $Link }
    if ($PSBoundParameters.ContainsKey('Link')) { 
        $null = $PSBoundParameters.Remove('Link') 
    }
    if ($PSBoundParameters.ContainsKey('Type')) {
        $null = $PSBoundParameters.Remove('Type')
        $TokenParameters['Type'] = $Type 
    }    
    if ($PSBoundParameters.ContainsKey('Credential')) {
        $null = $PSBoundParameters.Remove('Credential')
        $Key = $Credential.GetNetworkCredential()
        $TokenParameters['KeyType'] = $Key.UserName
        $TokenParameters['Key'] = $Key.Password
    }
    $TokenParameters['Method'] = $Method
    $TokenParameters['Date'] = $PSBoundParameters['Headers']['x-ms-date'] = [datetime]::UtcNow.ToString('R')
    
    $PSBoundParameters['Headers']['Authorization'] = New-DocumentDbToken @TokenParameters
    
    # Invoke-Restmethod throws terminating errors for several HttpStatusCodes.
    # This try/catch block allows those errors to be passed to custom error
    # handling routines upstream via ErrorVariable parameters and prevents the
    # halting of asynchronous jobs running in separate runspaces.
    try { 
        Invoke-RestMethod @PSBoundParameters
    } catch { 
        if ($PSBoundParameters.ContainsKey('ErrorVariable')) { 
            $PSBoundParameters['ErrorVariable'] = $_
        } else { 
            throw
        }
    }
}