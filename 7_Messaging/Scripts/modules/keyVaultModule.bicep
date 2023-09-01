param location string
param tenantId string = subscription().tenantId
param keyVaultSku string
param keyVaultName string

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    enablePurgeProtection: null
    enableSoftDelete: false
    accessPolicies: []
    sku: {
      name: keyVaultSku
      family: 'A'
    }
  }
}
