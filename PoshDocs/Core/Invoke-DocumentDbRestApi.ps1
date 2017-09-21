function Invoke-DocumentDbRestApi {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
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

    if ($PSBoundParameters.ContainsKey('PartitionKey')) { $Headers['x-ms-documentdb-partitionkey'] = ConvertTo-Json $PartitionKey -Compress }
    
    $TokenParameters = @{ Link = $Link }

    if ($PSBoundParameters.ContainsKey('Type')) { $TokenParameters['Type'] = $Type }
    
    if ($PSBoundParameters.ContainsKey('Credential')) { 
        $Key = $Credential.GetNetworkCredential()
        $TokenParameters['KeyType'] = $Key.UserName
        $TokenParameters['Key'] = $Key.Password
    }

    $TokenParameters['Method'] = $RestParameters['Method'] = $Method
    $TokenParameters['Date'] = $Headers['x-ms-date'] = [datetime]::UtcNow.ToString('R')
    
    $Headers['Authorization'] = New-DocumentDbToken @TokenParameters

    $RestParameters['Headers'] = $Headers
    
    # Invoke-Restmethod throws terminating errors for several HttpStatusCodes.
    # This try/catch block allows those errors to be passed to custom error
    # handling routines upstream via ErrorVariable parameters and prevents the
    # halting of asynchronous jobs running in separate runspaces.
    try { Invoke-RestMethod @RestParameters }
    catch { 
        if ($PSBoundParameters.ContainsKey('ErrorVariable')) { $PSBoundParameters['ErrorVariable'] = $_ }
        else { throw }
    }
}