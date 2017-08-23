function Remove-DocumentDbResource {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Link},

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
    $RestParameters = @{ Uri = '{0}{1}' -f $Uri.AbsoluteUri, $Link }
    
    $TokenParameters = @{ ResourceType = $Link.Split('/')[-2]; ResourceLink = $Link }
    $TokenParameters['Date'] = $Headers['x-ms-date'] = [datetime]::UtcNow.ToString('R')
    $TokenParameters['Method'] = $RestParameters['Method'] = 'Delete'

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