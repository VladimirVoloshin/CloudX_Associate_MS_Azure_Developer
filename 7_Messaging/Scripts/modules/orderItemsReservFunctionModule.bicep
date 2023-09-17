param deploymentPrefix string
var functionPrefix = '${deploymentPrefix}-ordires'
param location string
param containerRegistryName string
param imageName string
param storageAccountName string
param serviceBusConnStrRef string
param serviceBusOrderCreatedQueueName string
param keyVaultName string
param orderResItemsFunctionUrlSecretName string
param tenantId string = subscription().tenantId
param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array
param appInsightsConnRef string

var appServicePlanName = '${functionPrefix}-plan'
var functionName = '${functionPrefix}-func'

resource storageAccountRef 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  kind: 'functionapp,linux,container'
  properties: {
    reserved: true
  }
  sku: {
    tier: 'Standard'
    name: 'S1'
    size: 'S1'
    family: 'S'
    capacity: 1
  }
}

resource orderItemsReserverFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: functionName
  location: location
  kind: 'functionapp,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {}
  properties: {
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountRef.listKeys().keys[0].value}'
        }
        {
          name: 'ContainerName'
          value: 'order-upload'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountRef.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: listCredentials(resourceId('Microsoft.ContainerRegistry/registries', containerRegistryName), '2020-11-01-preview').passwords[0].value
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: containerRegistryName
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'OrderCreatedConnectionString'
          value: serviceBusConnStrRef
        }
        {
          name: 'OrderCreatedQueueName'
          value: serviceBusOrderCreatedQueueName
        }
        {
          name: 'ApplicationInsights__ConnectionString'
          value: appInsightsConnRef
        }
        {
          name: 'EmailFailureServiceUrl'
          value: 'https://prod-55.eastus.logic.azure.com:443/workflows/8fcce6a79a754717aaa7e098a43e01a2/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=ES9dzq4X8IgPWkdSidbxxFxPskZd8djgft4kyhCoajs'
        }
      ]
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${imageName}:latest'
    }
  }
}

resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: orderItemsReserverFunction.identity.principalId
        tenantId: tenantId
        permissions: {
          keys: keyVaultKeysPermissions
          secrets: keyVaultSecretsPermissions
        }
      }
    ]
  }
}

resource orderResItemsFunctionCodeSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVaultRef
  name: orderResItemsFunctionUrlSecretName
  properties: {
    value: 'https://${functionName}.azurewebsites.net//api/OrderItemsReserverFunction?code=${storageAccountRef.listKeys().keys[0]}'
  }
}

output orderItemsResFunctionUrlSecretRef string = '@Microsoft.KeyVault(SecretUri=${reference(orderResItemsFunctionUrlSecretName).secretUriWithVersion})'
output orderResFunctionName string = functionName
