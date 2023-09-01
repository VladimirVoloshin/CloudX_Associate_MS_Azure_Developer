param deploymentPrefix string
param location string
param storageAccountType string

var storageAccountName = '${deploymentPrefix}storage'
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

output storageAccountName string = storageAccountName
