param (
    [Parameter(Mandatory = $true)]
    [string]$AdminUsername,

    [Parameter(Mandatory = $true)]
    [string]$AdminPassword,

    [Parameter(Mandatory = $true)]
    [string]$NewUserPassword,

    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityClientId,

    [Parameter(Mandatory = $true)]
    [string]$domainName
)
<#
    .DESCRIPTION
    This script sets up Active Directory (AD) by provisioning users  from Azure Active Directory.

    .PARAMETER AdminUsername
    The username of the admin account used to connect to Active Directory.

    .PARAMETER AdminPassword
    The password of the admin account used to connect to Active Directory.

    .PARAMETER NewUserPassword
    The password to set for the newly provisioned users in Active Directory.

    .PARAMETER ManagedIdentityClientId
    The client ID of the managed identity used to authenticate with Azure Active Directory.

    .PARAMETER domainName
    The name of the domain associated with the Active Directory.

    .EXAMPLE
    .\AADSetup.ps1 -AdminUsername "admin" -AdminPassword (ConvertTo-SecureString "password" -AsPlainText -Force) -NewUserPassword (ConvertTo-SecureString "newpassword" -AsPlainText -Force) -ManagedIdentityClientId "12345678-1234-1234-1234-1234567890ab" -domainName "contoso.com"
#>

# Install the Microsoft Graph PowerShell module if it is not already installed
if (-not (Get-Module -Name Microsoft.Graph -ListAvailable)) {
    Install-Module -Name Microsoft.Graph -Force
}
# Import the required modules
Import-Module Microsoft.Graph
Import-Module ActiveDirectory
# Connect to Azure Active Directory
$domainUsername = "$domainName\$AdminUsername"
$domainCredential = New-Object System.Management.Automation.PSCredential($domainUsername, (ConvertTo-SecureString $AdminPassword -AsPlainText -force))
Connect-MgGraph -Scopes "User.Read.All" -Identity -ClientId $ManagedIdentityClientId

# Download all cloud users
$cloudUsers = Get-MgUser -All

# Provision users in Active Directory
$ouName = "Entra"
$domainDN = $domainName -replace "\.", ",DC="
$ouPath = "OU=$ouName,DC=$domainDN"  # Replace with your domain information

foreach ($user in $cloudUsers) {
    $userPrincipalName = $user.UserPrincipalName
    $displayName = $user.DisplayName
    $givenName = $user.GivenName
    $surname = $user.Surname
    $mail = $user.Mail
    $samAccountName = $user.UserPrincipalName.Split("@")[0]

    $newUserParams = @{
        SamAccountName        = $samAccountName
        UserPrincipalName     = $userPrincipalName
        Name                  = $displayName
        GivenName             = $givenName
        Surname               = $surname
        EmailAddress          = $mail
        DisplayName           = $displayName
        Enabled               = $true
        Path                  = $ouPath
        Credential            = $domainCredential
        AccountPassword       = (ConvertTo-SecureString $NewUserPassword -AsPlainText -Force)
        ChangePasswordAtLogon = $false
        PasswordNeverExpires  = $false
        PasswordNotRequired   = $false
    }
    New-ADUser @newUserParams
}
