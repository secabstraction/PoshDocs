function New-DocumentDbResource {
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
        ${ApiVersion} = '2017-01-19',

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )

    $ApiParameters = @{
        ResourceType = $Type
        Method = 'Post'
    }
    
    if ($PSBoundParameters['Link']) { 
        $ApiParameters['Uri'] = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Type
        $ApiParameters['ResourceLink'] = $Link
    }
    else { $ApiParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Type }
    
    $PSBoundParameters.Keys | ForEach-Object {
        if ($_ -notin @('Uri','Link','Type')) { $ApiParameters[$_] = $PSBoundParameters[$_] }
    }
    
    Invoke-DocumentDbRestApi @ApiParameters
}