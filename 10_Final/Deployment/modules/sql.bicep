param location string = resourceGroup().location
param serverName string = 'eShopOnWeb-sql-server'
param catalogDbName string = 'CatalogDb'
param identityDBName string = 'identity'
param sqlAdminLogin string = 'sqlUser'
param keyVaultName string
param catalogConnectionSecretName string
param identityConnectionSecretName string
@secure()
#disable-next-line secure-parameter-default
param sqlAdminPass string = 'asjfdjakfhsld@@333S3kdd!!ff'

#disable-next-line no-hardcoded-env-urls
var sqlServerUrl = '${serverName}.database.windows.net'
var sqlSku = 'Basic'

resource sqlServerInstance 'Microsoft.Sql/servers@2023-02-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPass
  }
}

resource SQLAllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2023-02-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServerInstance
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource catalogDb_database 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServerInstance
  name: catalogDbName
  location: location
  sku: {
    name: sqlSku
  }
}

resource identity_database 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServerInstance
  name: identityDBName
  location: location
  sku: {
    name: sqlSku
  }
}

resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource secretCatalogConnStringRes 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVaultRef
  name: catalogConnectionSecretName
  properties: {
    value: 'Server=tcp:${sqlServerUrl},1433;Initial Catalog=${catalogDbName} ;Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}
resource secretIdentityConnStringRes 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVaultRef
  name: identityConnectionSecretName
  properties: {
    value: 'Server=tcp:${sqlServerUrl},1433;Initial Catalog=${identityDBName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

output secretCatalogConnStringRef string = '@Microsoft.KeyVault(SecretUri=${reference(catalogConnectionSecretName).secretUriWithVersion})'
output identityConnSecretRef string = '@Microsoft.KeyVault(SecretUri=${reference(identityConnectionSecretName).secretUriWithVersion})'
