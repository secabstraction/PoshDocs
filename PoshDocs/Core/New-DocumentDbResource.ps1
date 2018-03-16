<#
    .SYNOPSIS
    Creates a resource in Azure Document DB.

    .DESCRIPTION
    New-DocumentDbResource creates a resource in Azure Document DB.

    .PARAMETER Link
    Specifies the path where the resource will be created.

    .PARAMETER Type
    Specifies the type of resource to create.

    .PARAMETER Body
    Specifies the parameters from which the resource will be created.

    .PARAMETER Headers
    Specifies any custom headers to pass to the Azure Document DB REST API.

    .PARAMETER Uri
    Specifies the URI of the Document DB REST endpoint.

    .PARAMETER Version
    Specifies the version of the Document DB REST API.

    .PARAMETER Credential
    Specifies the credentials for accessing the Document DB REST endpoint.

    .EXAMPLE
    $Database = 'poshdoc-2018.02.02'
    
    $Resource = @{
        Link = "dbs/$Database"
        Type = 'dbs'
        Body = '{{"id":"{0}"}}' -f $Database
    }

    $RESTEndpoint = @{
        Uri = 'https://my.documents.azure.com'
        Credential = Get-Credential 'master'
    }

    New-DocumentDbResource @Resource @RESTEndpoint
    
    .NOTES
    Author: Jesse Davis (@secabstraction)
    License: BSD 3-Clause

    .LINK
    https://docs.microsoft.com/en-us/rest/api/documentdb/common-tasks-using-the-documentdb-rest-api
#>
function New-DocumentDbResource {
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
        ${Uri},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Version},

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )
    
    $PSBoundParameters['Method'] = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post

    if ($PSBoundParameters.ContainsKey('Link')) { 
        $PSBoundParameters['Uri'] = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Type
    } else { 
        $PSBoundParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Type
    }
    
    Invoke-DocumentDbRestApi @PSBoundParameters
}