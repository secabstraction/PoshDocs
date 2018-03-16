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
function Remove-DocumentDbResource {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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

    $PSBoundParameters['Type'] = $Link.Split('/')[-2]
    $PSBoundParameters['Uri'] = '{0}{1}' -f $Uri.AbsoluteUri, $Link
    $PSBoundParameters['Method'] = [Microsoft.PowerShell.Commands.WebRequestMethod]::Delete
    
    Invoke-DocumentDbRestApi @PSBoundParameters
}