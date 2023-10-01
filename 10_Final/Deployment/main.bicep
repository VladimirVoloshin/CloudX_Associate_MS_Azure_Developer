param location string = resourceGroup().location
param deploymentPrefix string = 'messaging${uniqueString(resourceGroup().id)}'

// key vault module
param keyVaultName string = '${deploymentPrefix}kvault'
param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array

module keyVaultModule 'modules/keyVaultModule.bicep' = {
  name: 'keyVaultModule'
  params: {
    location: location
    keyVaultName: keyVaultName
  }
}

// sql module
param catalogConnectionSecretName string
param identityConnectionSecretName string

module sqlModule 'modules/sql.bicep' = {
  name: 'sqlModule'
  dependsOn: [ keyVaultModule ]
  params: {
    catalogConnectionSecretName: catalogConnectionSecretName
    identityConnectionSecretName: identityConnectionSecretName
    keyVaultName: keyVaultName
    location: location
    deploymentPrefix: deploymentPrefix
  }
}

// container registry module
var containerRegistryName = '${deploymentPrefix}registry'
module acrModule 'modules/containerRegistryModule.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    containerRegistryName: containerRegistryName
  }
}

// service bus
param serviceBusOrderCreatedQueueName string
module serviceBusModule 'modules/serviceBusModule.bicep' = {
  name: 'ServiceBusModule'
  dependsOn: [ keyVaultModule ]
  params: {
    location: location
    serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
    keyVaultName: keyVaultName
    deploymentPrefix: deploymentPrefix
  }
}

//storage account module
module storageAccountModule 'modules/storageAccountModule.bicep' = {
  name: 'storageAccountModule'
  params: {
    deploymentPrefix: deploymentPrefix
    location: location
  }
}

// app insights module
module appInsightsModule 'modules/appInsightsModule.bicep' = {
  name: 'appInsightsModule'
  dependsOn: [ keyVaultModule, storageAccountModule ]
  params: {
    keyVaultName: keyVaultName
    location: location }
}

// order items reserver function module
param orderItemsReserverImageName string
module orderItemsReserverFunctionModule 'modules/orderItemsReservFunctionModule.bicep' = {
  name: 'orderItemsReserverFunction'
  dependsOn: [ storageAccountModule, acrModule ]
  params: {
    imageName: orderItemsReserverImageName
    containerRegistryName: containerRegistryName
    deploymentPrefix: deploymentPrefix
    location: location
    storageAccountName: storageAccountModule.outputs.storageAccountName
    serviceBusConnStrRef: serviceBusModule.outputs.serviceBusConnStrRef
    serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
    keyVaultName: keyVaultName
    keyVaultKeysPermissions: keyVaultKeysPermissions
    keyVaultSecretsPermissions: keyVaultSecretsPermissions
    appInsightsConnRef: appInsightsModule.outputs.appInsightsConnRef
  }
}

// webApp module
param imageWebName string
module webAppModule 'modules/webAppModule.bicep' = {
  name: 'webApp'
  dependsOn: [ serviceBusModule, keyVaultModule ]
  params: {
    catalogConnectionSecretRef: sqlModule.outputs.secretCatalogConnStringRef
    identityConnSecretRef: sqlModule.outputs.identityConnSecretRef
    containerRegistryName: containerRegistryName
    deploymentPrefix: deploymentPrefix
    imageWebName: imageWebName
    location: location
    keyVaultKeysPermissions: keyVaultKeysPermissions
    keyVaultName: keyVaultName
    keyVaultSecretsPermissions: keyVaultSecretsPermissions
    serviceBusConnStrRef: serviceBusModule.outputs.serviceBusConnStrRef
    serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
    orderItemsResFunctionUrlSecretRef: orderItemsReserverFunctionModule.outputs.orderItemsResFunctionUrlSecretRef
    appInsightsConnRef: appInsightsModule.outputs.appInsightsConnRef
  }
}

output containerRegistryName string = containerRegistryName
output webAppName string = webAppModule.outputs.webAppName
output orderResFunName string = orderItemsReserverFunctionModule.outputs.orderResFunctionName
