param location string
param deploymentPrefix string
param imageName string
param containerRegistryName string
param storageAccountName string
param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array
param appInsightsConnRef string
param databaseName string
param cosmoDbConnStringRef string
param keyVaultName string
param tenantId string = subscription().tenantId

var functionPrefix = '${deploymentPrefix}-delorderreserv'
var appServicePlanName = '${functionPrefix}-plan'
var functionName = '${functionPrefix}-func'

resource storageAccountRef 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
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

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountRef.listKeys().keys[0].value}'
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
          name: 'DELIVERY_ORDER_PROCESSOR_DB_CONNECTION'
          value: cosmoDbConnStringRef
        }
        {
          name: 'DELIVERY_ORDER_PROCESSOR_DB_NAME'
          value: databaseName
        }
        {
          name: 'DELIVERY_ORDER_PROCESSOR_CONTAINER_NAME'
          value: containerRegistryName
        }
        {
          name: 'ApplicationInsights__ConnectionString'
          value: appInsightsConnRef
        }
      ]
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${imageName}:latest'
    }
    httpsOnly: true
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: functionApp.identity.principalId
        tenantId: tenantId
        permissions: {
          keys: keyVaultKeysPermissions
          secrets: keyVaultSecretsPermissions
        }
      }
    ]
  }
}
