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
        [string[]]
        ${PartitionKey},

        [ValidateNotNullOrEmpty()]
        [uri]
        ${Uri} = 'https://localhost:8081',
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Version},
        
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )    

    $ApiParameters = @{
        Uri = '{0}{1}' -f $Uri.AbsoluteUri, $Link
        Type = $Link.Split('/')[-2]
        Link = $Link
        Method = 'Delete'
    }
    
    foreach ($Key in $PSBoundParameters.Keys) {
        if ($Key -notin @('Uri','Link')) { $ApiParameters[$Key] = $PSBoundParameters[$Key] }
    }
    
    Invoke-DocumentDbRestApi @ApiParameters
}