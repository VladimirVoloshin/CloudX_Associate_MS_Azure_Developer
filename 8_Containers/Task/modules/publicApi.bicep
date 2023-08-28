param location string
param publicApiAppName string
param publicApiSku string
param containerRegistryName string
param publicApiAppServicePlanName string
param imagePublicApiName string

param catalogConnString string
param identityConnString string

resource plan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: publicApiAppServicePlanName
  location: location
  sku: {
    name: publicApiSku
    capacity: 1
  }
  properties: {
    reserved: true
  }
  kind: 'app,linux,container'
}

resource app 'Microsoft.Web/sites@2020-06-01' = {
  name: publicApiAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      minTlsVersion: '1.2'
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${imagePublicApiName}:latest'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
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
      ]
    }
  }
}

resource connectionstringsWeb 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'connectionstrings'
  parent: app
  properties: {
    CatalogConnection: {
      value: catalogConnString
      type: 'SQLServer'
    }
    IdentityConnection: {
      value: identityConnString
      type: 'SQLServer'
    }
  }
}

output publicApiIdentityId string = app.identity.principalId
