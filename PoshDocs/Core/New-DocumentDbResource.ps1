function New-DocumentDbResource {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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
        
        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Body},
        
        [Parameter(Position=3)]
        [hashtable]
        ${Headers},
        
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
        Type = $Type
        Method = 'Post'
    }
    
    if ($PSBoundParameters['Link']) { 
        $ApiParameters['Uri'] = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Type
        $ApiParameters['Link'] = $Link
    }
    else { $ApiParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Type }
    
    foreach ($Key in $PSBoundParameters.Keys) {
        if ($Key -notin @('Uri','Link','Type')) { $ApiParameters[$Key] = $PSBoundParameters[$Key] }
    }
    
    Invoke-DocumentDbRestApi @ApiParameters
}