function New-DocumentDbToken {
    <#        
        .NOTES
        Author: Jesse Davis (@secabstraction)
        License: BSD 3-Clause
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType('System.String')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        ${Method},
        
        [ValidateSet('dbs','colls','docs','users','permissions','sprocs','triggers','udfs','attachments','offers')]
        [string]
        ${Type},
        
        [string]
        ${Link},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Date},
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${Key} = 'C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==', # Emulator master key
        
        [ValidateSet('master','resource')]
        [string]
        ${KeyType} = 'master',
        
        [ValidateNotNullOrEmpty()]
        [string]
        ${TokenVersion} = '1.0'
    )  

    $HmacSha256 = New-Object 'System.Security.Cryptography.HMACSHA256' -ArgumentList @(,[Convert]::FromBase64String($Key))  

    $PayLoad = "{0}`n{1}`n{2}`n{3}`n{4}`n" -f $Method.ToString().ToLower(), $Type, $Link, $Date.ToLower(), [string]::Empty

    $HashPayLoad = $HmacSha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PayLoad))

    try { [System.Web.HttpUtility]::UrlEncode(('type={0}&ver={1}&sig={2}' -f $KeyType,$TokenVersion,([Convert]::ToBase64String($HashPayLoad)))) }
    catch {
        Add-Type -AssemblyName 'System.Web'
        [System.Web.HttpUtility]::UrlEncode(('type={0}&ver={1}&sig={2}' -f $KeyType,$TokenVersion,([Convert]::ToBase64String($HashPayLoad))))
    }
}