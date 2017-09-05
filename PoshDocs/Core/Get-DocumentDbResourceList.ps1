function Get-DocumentDbResourceList {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [ValidateSet('dbs','colls','docs','users','permissions','sprocs','triggers','udfs','attachments','offers')]
        [string]
        ${Type},

        [Parameter(Position=1)]
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

    $ApiParameters = @{ Method = 'Get' }
    
    foreach ($Key in $PSBoundParameters.Keys) {
        if ($Key -notin @('Uri','Link')) { $ApiParameters[$Key] = $PSBoundParameters[$Key] }
    }
    
    if ($PSBoundParameters['Link']) { 
        $ApiParameters['Uri'] = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Type
        $ApiParameters['Link'] = $Link
    }
    else { $ApiParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Type }

    Invoke-DocumentDbRestApi @ApiParameters
}