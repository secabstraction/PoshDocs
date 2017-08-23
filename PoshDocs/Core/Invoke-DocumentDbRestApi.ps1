function Invoke-DocumentDbRestApi {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
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
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('dbs','colls','docs','users','permissions','sprocs','triggers','udfs','attachments','offers')]
        [string]
        ${ResourceType},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${ResourceLink},

        [ValidateNotNullOrEmpty()]
        [string[]]
        ${PartitionKey},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Version} = '2017-01-19',

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )
    
    $RestParameters = @{ Uri = $Uri }
    
    if ($PSBoundParameters.ContainsKey('Body')) { $RestParameters['Body'] = $Body }
    
    if ($PSBoundParameters.ContainsKey('Headers')) { $Headers['x-ms-version'] = $Version }
    else { $Headers = @{ 'x-ms-version' = $Version } }

    if ($PSBoundParameters.ContainsKey('PartitionKey')) { 
        $Headers['x-ms-documentdb-partitionkey'] = ConvertTo-Json $PartitionKey -Compress
    }
    
    $TokenParameters = @{ 
        ResourceType = $ResourceType
        ResourceLink = $ResourceLink
    }
    
    if ($PSBoundParameters.ContainsKey('Credential')) { 
        $Key = $Credential.GetNetworkCredential()
        $TokenParameters['KeyType'] =  $Key.UserName
        $TokenParameters['Key'] =  $Key.Password
    }

    $TokenParameters['Method'] = $RestParameters['Method'] = $Method
    $TokenParameters['Date'] = $Headers['x-ms-date'] = [datetime]::UtcNow.ToString('R')
    
    $Headers['Authorization'] = New-DocumentDbToken @TokenParameters

    $RestParameters['Headers'] = $Headers
    
    try { Invoke-RestMethod @RestParameters }
    catch { 
        if ($PSBoundParameters.ContainsKey('ErrorVariable')) {
            $PSBoundParameters['ErrorVariable'] = $_
        }
        # Invoke-Restmethod throws terminating errors for several HttpStatusCodes.
        # This try/catch block allows those errors to be passed to custom error
        # handling routines upstream via ErrorVariable parameters and prevents the
        # halting of asynchronous jobs running in separate runspaces.
    }
}