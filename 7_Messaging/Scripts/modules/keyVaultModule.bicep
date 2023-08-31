param location string
param tenantId string = subscription().tenantId
param webAppIdentityId string
param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array
param keyVaultSku string
param keyVaultName string

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    enablePurgeProtection: null
    enableSoftDelete: false
    accessPolicies: [
      // {
      //   objectId: webAppIdentityId
      //   tenantId: tenantId
      //   permissions: {
      //     keys: keyVaultKeysPermissions
      //     secrets: keyVaultSecretsPermissions
      //   }
      // }
    ]
    sku: {
      name: keyVaultSku
      family: 'A'
    }
  }
}
