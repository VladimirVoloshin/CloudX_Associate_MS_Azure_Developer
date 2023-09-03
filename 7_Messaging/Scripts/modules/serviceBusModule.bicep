param deploymentPrefix string
param serviceBusOrderCreatedQueueName string
param location string
param keyVaultName string
param serviceBusOrderConnNameSecret string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: '${deploymentPrefix}ordermessagingbus'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: serviceBusNamespace
  name: serviceBusOrderCreatedQueueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

var serviceBusEndpoint = '${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
resource serviceBusConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVaultRef
  name: serviceBusOrderConnNameSecret
  properties: {
    value: listKeys(serviceBusEndpoint, serviceBusNamespace.apiVersion).primaryConnectionString
  }
}

output serviceBusConnStrRef string = '@Microsoft.KeyVault(SecretUri=${reference(serviceBusOrderConnNameSecret).secretUriWithVersion})'
