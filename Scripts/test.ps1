param( 
    [string]$vaultname
)
Import-Module -Name ./WindowsCompatibility -Force
Import-WinModule -Name PKI -Verbose -Force
#Root certificate properties
$root = @{
    Type              = "Custom" 
    KeySpec           = "Signature" 
    Subject           = "CN=Azure Firewall Root CA,O=Self Signed,ST=US,C=US" 
    KeyExportPolicy   = "Exportable"
    HashAlgorithm     = "sha256" 
    KeyLength         = 4096
    NotAfter          = (Get-Date).AddYears(3).ToUniversalTime()
    CertStoreLocation = "Cert:\currentuser\My"
    KeyUsageProperty  = "Sign" 
    KeyUsage          = "DigitalSignature", "CertSign", "CRLSign"
    TextExtension     = @("2.5.29.19={text}CA=true")
}
#Genereate Root Certificate
$rootcert = New-SelfSignedCertificate @root
#Import Certificate to key vault
$password=ConvertTo-SecureString -String "SuperSecret123" -Force -AsPlainText
$path="Cert:\currentuser\My\" + $rootcert.thumbprint
$certpath="$env:TEMP\AzureFirewallRoot.pfx"
Export-PfxCertificate -Cert $path -FilePath $certpath -Password $password
Import-AzKeyVaultCertificate -VaultName $keyvault -Name "AzureFirewallRoot" -FilePath $certpath -Password $password

$ca = @{
    Type              = "Custom" 
    KeySpec           = "Signature" 
    Subject           = "CN=Azure Firewall Intermediate CA,O=Self Signed,ST=US,C=US" 
    KeyExportPolicy   = "Exportable"
    HashAlgorithm     = "sha256" 
    KeyLength         = 4096
    NotAfter          = (Get-Date).AddYears(3).ToUniversalTime()
    CertStoreLocation = "Cert:\currentuser\My"
    KeyUsageProperty  = "Sign" 
    KeyUsage          = "DigitalSignature", "CertSign", "CRLSign"
    TextExtension     = @("2.5.29.19={text}CA=true&pathlength=1")
    Signer = $cert    
}
#Genereate Intermediate Certificate
$cacert=New-SelfSignedCertificate @ca
#Import certificate to Key Vault
$password=ConvertTo-SecureString -String "SuperSecret123" -Force -AsPlainText
$path="Cert:\currentuser\My\" + $cacert.thumbprint
Export-PfxCertificate -Cert $path -FilePath "$env:TEMP\AzureFirewallIntermediate.pfx" -ChainOption EndEntityCertOnly -Password $password
$fwcert=Import-AzKeyVaultCertificate -VaultName $keyvault -Name "AzureFirewallCA" -FilePath "$env:TEMP\AzureFirewallIntermediate.pfx" -Password $password

$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['fwcertID'] = $fwcert.SecretId
