param location string
param tenantId string = subscription().tenantId
param keyVaultName string

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    enablePurgeProtection: null
    enableSoftDelete: false
    accessPolicies: []
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}
