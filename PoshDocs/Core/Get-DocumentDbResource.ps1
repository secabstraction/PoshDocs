<#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

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
function Get-DocumentDbResource {
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
        ${Uri},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Version},

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        ${Credential} = [System.Management.Automation.PSCredential]::Empty
    )

    $PSBoundParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Link
    $PSBoundParameters['Type'] = $Link.Split('/')[-2]
    $PSBoundParameters['Method'] = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get

    Invoke-DocumentDbRestApi @PSBoundParameters
}