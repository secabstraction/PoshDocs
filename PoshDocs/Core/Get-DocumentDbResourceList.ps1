<#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Type
    Parameter description

    .PARAMETER Link
    Parameter description

    .PARAMETER PartitionKey
    Parameter description

    .PARAMETER Uri
    Parameter description

    .PARAMETER Version
    Parameter description

    .PARAMETER Credential
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    Author: Jesse Davis (@secabstraction)
    License: BSD 3-Clause
#>
function Get-DocumentDbResourceList {
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
        ${Uri},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Version},
        
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )

    $PSBoundParameters['Method'] = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get
        
    if ($PSBoundParameters.ContainsKey('Link')) {
        $PSBoundParameters['Uri'] = '{0}{1}/{2}' -f $Uri.AbsoluteUri, $Link, $Type
    } else { 
        $PSBoundParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Type
    }

    Invoke-DocumentDbRestApi @PSBoundParameters
}