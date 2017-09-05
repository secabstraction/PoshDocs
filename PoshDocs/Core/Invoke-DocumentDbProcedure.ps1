function Invoke-DocumentDbProcedure {
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

        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Procedure},
        
        [ValidateNotNullOrEmpty()]
        [object[]]
        ${Parameters},
        
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
        Uri = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Procedure
        Body = ConvertTo-Json $Parameters -Compress -Depth 4
        Link = '{0}/{1}' -f $Link, $Procedure
        Type = 'sprocs'
        Method = 'Post'
    }

    $LocalParameters = @('Uri','Link','Procedure','Parameters')
    
    foreach ($Key in $PSBoundParameters.Keys) {
        if ($Key -notin $LocalParameters) { $ApiParameters[$Key] = $PSBoundParameters[$Key] }
    }
    
    Invoke-DocumentDbRestApi @ApiParameters
}