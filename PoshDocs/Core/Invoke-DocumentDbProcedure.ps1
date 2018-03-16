<#
    .SYNOPSIS
    Executes a Document DB stored procedure.

    .DESCRIPTION
    Invoke-DocumentDbProcedure executes a Document DB stored procedure.

    .PARAMETER Link
    Specifies the path to the stored procedure.

    .PARAMETER Procedure
    Specifies the name of the stored procedure.

    .PARAMETER Parameters
    Specifies the parameters to pass to the stored procedure.

    .PARAMETER PartitionKey
    Specifies the property used to partition data across a collection. References the PartitionKey for collections that already exist.

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
    https://docs.microsoft.com/en-us/rest/api/documentdb/stored-procedures
#>
function Invoke-DocumentDbProcedure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Database},
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Collection},

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
        ${Uri},

        [ValidateNotNullOrEmpty()]
        [string]
        ${Version},

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )

    $null = $PSBoundParameters.Remove('Procedure')
    if ($PSBoundParameters.ContainsKey('Parameters')) {
        $null = $PSBoundParameters.Remove('Parameters')
    }

    $PSBoundParameters['Link'] = 'dbs/{0}/colls/{1}/sprocs/{2}' -f $Database, $Collection, $Procedure
    $PSBoundParameters['Method'] = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
    $PSBoundParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $PSBoundParameters['Link']
    $PSBoundParameters['Body'] = ConvertTo-Json $Parameters -Compress -Depth 4
    $PSBoundParameters['Type'] = 'sprocs'
        
    Invoke-DocumentDbRestApi @PSBoundParameters
}