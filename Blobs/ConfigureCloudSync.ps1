[CmdletBinding(DefaultParameterSetName = 'Credentials')]
param(
    [Parameter(Mandatory=$true)]
    [Parameter(ParameterSetName = 'Passwords')]
    [string]$hybridAdminUPN,
    
    [Parameter(Mandatory=$true)]
    [Parameter(ParameterSetName = 'Passwords')]
    [securestring]$hybridAdminPassword,

    [Parameter(Mandatory = $true)]
    [Parameter(ParameterSetName = 'Passwords')]
    [string]$domainAdminUPN,
    
    [Parameter(Mandatory = $true)]
    [Parameter(ParameterSetName = 'Passwords')]
    [securestring]$domainAdminPassword,

    [Parameter(Mandatory=$true)]
    [Parameter(ParameterSetName = 'Credentials')]
    [System.Management.Automation.PSCredential]$hybridAdminCredential,
    
    [Parameter(Mandatory = $true)]
    [Parameter(ParameterSetName = 'Credentials')]
    [System.Management.Automation.PSCredential]$domainAdminCredential,

    [Parameter(Mandatory = $true)]
    [Parameter(ParameterSetName = 'Passwords')]
    [Parameter(ParameterSetName = 'Credentials')]
    [string]$domainname
)

Import-Module "C:\Program Files\Microsoft Azure AD Connect Provisioning Agent\Microsoft.CloudSync.PowerShell.dll" 
if ($PSCmdlet.ParameterSetName -eq 'Passwords'){
    $hybridAdminCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($hybridAdminUPN, $hybridAdminPassword) 
}
Connect-AADCloudSyncAzureAD -Credential $hybridAdminCreds
if ($PSCmdlet.ParameterSetName -eq 'Passwords'){
    $domainAdminCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($domainAdminUPN, $domainAdminPassword) 
}
Add-AADCloudSyncGMSA -Credential $domainAdminCreds
Add-AADCloudSyncADDomain -DomainName $domainname -Credential $domainAdminCreds 

Restart-Service -Name AADConnectProvisioningAgent  
