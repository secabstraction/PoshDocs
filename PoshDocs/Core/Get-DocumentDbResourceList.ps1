function Get-DocumentDbResourceList {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Link},

        [Parameter(Position=1, Mandatory=$true)]
        [ValidateSet('dbs','colls','docs','users','permissions','sprocs','triggers','udfs','attachments','offers')]
        [string]
        ${Type},
        
        [Parameter(Position=3)]
        [string[]]
        ${PartitionKey},

        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri} = 'https://localhost:8081',
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${ApiVersion} = '2017-01-19',
        
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )
    
    $Headers = @{ 'x-ms-version' = $ApiVersion }
    
    if ($PSBoundParameters['PartitionKey']) { 
        $Headers['x-ms-documentdb-partitionkey'] = ConvertTo-Json $PartitionKey -Compress
    }
    
    $TokenParameters = @{ ResourceType = $Type }
    
    if ($PSBoundParameters['Link']) { 
        $TokenParameters['ResourceLink'] = $Link
        $RestParameters = @{ Uri = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Type }
    }
    else { $RestParameters = @{ Uri = '{0}{1}' -f $Uri.AbsoluteUri, $Type } }
    
    $TokenParameters['Method'] = $RestParameters['Method'] = 'Get'
    $TokenParameters['Date'] = $Headers['x-ms-date'] = [datetime]::UtcNow.ToString('R')

    if ($PSBoundParameters['Credential']) { 
        $Key = $Credential.GetNetworkCredential()
        $TokenParameters['KeyType'] = $Key.UserName
        $TokenParameters['Key'] = $Key.Password
    }

    $Headers['Authorization'] = New-CosmosDbToken @TokenParameters
    $RestParameters['Headers'] = $Headers

    try { Invoke-RestMethod @RestParameters }
    catch { 
        # Invoke-Restmethod throws terminating errors for several HttpStatusCodes.
        # This empty catch block allows those errors to be passed to custom error
        # handling routines upstream via ErrorVariable parameters and prevents the
        # halting of asynchronous jobs running in object event handler runspaces.
    } 
}