param deploymentPrefix string
var functionPrefix = '${deploymentPrefix}-orderitemsreserve'
param location string
param containerRegistryName string
param imageName string

var appServicePlanName = '${functionPrefix}-plan'
var functionName = '${functionPrefix}-func'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'app,linux,container'
  properties: {
    reserved: true
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource orderItemsReserverFunction 'Microsoft.Web/sites@2021-01-01' = {
  name: functionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {}
  properties: {
    siteConfig: {
      appSettings: [
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
      ]
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${imageName}:latest'
    }
    serverFarmId: appServicePlan.id
  }
}
