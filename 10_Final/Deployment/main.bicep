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

// cosomos db module
module cosmosDbModule 'modules/cosmosDbModule.bicep' = {
  name: 'cosmosDb'
  dependsOn: [ keyVaultModule ]
  params: {
    deploymentPrefix: deploymentPrefix
    location: location
    keyVaultName: keyVaultName
  }
}

// // Delivery order processor function module
param deliveryOrderProcessorImageName string
module deliveryOrderProcessorFunctionModule 'modules/deliveryOrderProcessorModule.bicep' = {
  name: 'deliveryOrderProcessorFunction'
  dependsOn: [ storageAccountModule, acrModule, cosmosDbModule, appInsightsModule ]
  params: {
    imageName: deliveryOrderProcessorImageName
    containerRegistryName: containerRegistryName
    deploymentPrefix: deploymentPrefix
    location: location
    storageAccountName: storageAccountModule.outputs.storageAccountName
    keyVaultName: keyVaultName
    keyVaultKeysPermissions: keyVaultKeysPermissions
    keyVaultSecretsPermissions: keyVaultSecretsPermissions
    appInsightsConnRef: appInsightsModule.outputs.appInsightsConnRef
    cosmoDbConnStringRef: cosmosDbModule.outputs.cosmoDbConnStringRef
    databaseName: cosmosDbModule.outputs.databaseName
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

// public api module
param publicApiImageName string
module publicApiModule 'modules/publicApiModule.bicep' = {
  name: 'publicApiAppDeployment'
  dependsOn: [ keyVaultModule ]
  params: {
    containerRegistryName: containerRegistryName
    publicApiImageName: publicApiImageName
    deploymentPrefix: deploymentPrefix
    location: location
    catalogConnString: sqlModule.outputs.secretCatalogConnStringRef
    identityConnString: sqlModule.outputs.identityConnSecretRef
    keyVaultName: keyVaultName
    keyVaultSecretsPermissions: keyVaultSecretsPermissions
    keyVaultKeysPermissions: keyVaultKeysPermissions
  }
}

output containerRegistryName string = containerRegistryName
output webAppName string = webAppModule.outputs.webAppName
output publicApiName string = publicApiModule.outputs.publicApiName
output orderResFunName string = orderItemsReserverFunctionModule.outputs.orderResFunctionName
