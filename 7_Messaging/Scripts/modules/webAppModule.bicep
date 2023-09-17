param location string
param deploymentPrefix string
param webAppName string
param webAppSku string
param containerRegistryName string
param imageWebName string
param serviceBusConnStrRef string
param serviceBusOrderCreatedQueueName string
param appInsightsConnRef string

@secure()
param catalogConnectionSecretRef string
@secure()
param identityConnSecretRef string
param tenantId string = subscription().tenantId

param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array

param keyVaultName string

@secure()
param orderItemsResFunctionUrlSecretRef string

resource plan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: '${deploymentPrefix}-web-plan'
  location: location
  sku: {
    name: webAppSku
    capacity: 1
  }
  properties: {
    reserved: true
  }
  kind: 'app,linux,container'
}

resource app 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    //httpsOnly: true
    siteConfig: {
      //alwaysOn: true
      minTlsVersion: '1.2'
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${imageWebName}:latest'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'OrderItemsReserver__Url'
          value: orderItemsResFunctionUrlSecretRef
        }
        {
          name: 'OrderItemsReserver__IsEnabled'
          value: 'true'
        }
        {
          name: 'DeliveryOrderProcessor__Url'
          value: ''
        }
        {
          name: 'DeliveryOrderProcessor__IsEnabled'
          value: 'false'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
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
          name: 'Messaging__OrderServicebus__ConnectionString'
          value: serviceBusConnStrRef
        }
        {
          name: 'Messaging__OrderServicebus__OrderCreatedQueue'
          value: serviceBusOrderCreatedQueueName
        }
        {
          name: 'ApplicationInsights__ConnectionString'
          value: appInsightsConnRef
        }
      ]
    }
  }
}

resource connectionstringsWeb 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'connectionstrings'
  parent: app
  properties: {
    CatalogConnection: {
      value: catalogConnectionSecretRef
      type: 'SQLServer'
    }
    IdentityConnection: {
      value: identityConnSecretRef
      type: 'SQLServer'
    }
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: app.identity.principalId
        tenantId: tenantId
        permissions: {
          keys: keyVaultKeysPermissions
          secrets: keyVaultSecretsPermissions
        }
      }
    ]
  }
}

resource containerFileLogging 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'logs'
  kind: 'string'
  parent: app
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Information'
      }
    }
    detailedErrorMessages: {
      enabled: true
    }
    failedRequestsTracing: {
      enabled: true
    }
    httpLogs: {
      fileSystem: {
        enabled: true
        retentionInDays: 1
        retentionInMb: 35
      }
    }
  }
}
