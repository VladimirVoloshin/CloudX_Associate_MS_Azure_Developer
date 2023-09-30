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

// // app insights module
// param appInsightsConnStrSecretName string
// param appInsightsName string
// param appInsightsProjName string

// module appInsightsModule 'modules/appInsightsModule.bicep' = {
//   name: 'appInsightsModule'
//   dependsOn: [ keyVaultModule ]
//   params: {
//     appInsightsConnStrSecretName: appInsightsConnStrSecretName
//     appInsightsName: appInsightsName
//     appInsightsProjName: appInsightsProjName
//     keyVaultName: keyVaultName
//     location: location }
// }

//storage account module
module storageAccountModule 'modules/storageAccountModule.bicep' = {
  name: 'storageAccountModule'
  params: {
    deploymentPrefix: deploymentPrefix
    location: location
  }
}

// // order items reserver function module
// param orderItemsReserverImageName string
// param orderResItemsFunctionUrlSecretName string

// module orderItemsReserverFunctionModule 'modules/orderItemsReservFunctionModule.bicep' = {
//   name: 'orderItemsReserverFunction'
//   dependsOn: [ storageAccountModule, acrModule ]
//   params: {
//     containerRegistryName: acrModule.outputs.containerRegistryName
//     deploymentPrefix: deploymentPrefix
//     imageName: orderItemsReserverImageName
//     location: location
//     storageAccountName: storageAccountModule.outputs.storageAccountName
//     serviceBusConnStrRef: serviceBusModule.outputs.serviceBusConnStrRef
//     serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
//     keyVaultName: keyVaultName
//     orderResItemsFunctionUrlSecretName: orderResItemsFunctionUrlSecretName
//     keyVaultKeysPermissions: keyVaultKeysPermissions
//     keyVaultSecretsPermissions: keyVaultSecretsPermissions
//     appInsightsConnRef: appInsightsModule.outputs.appInsightsConnRef
//   }
// }

// // webApp module
// param imageWebName string
// param webAppSku string
// param webAppName string = '${deploymentPrefix}-web-app'

// module webAppModule 'modules/webAppModule.bicep' = {
//   name: 'webApp'
//   dependsOn: [ serviceBusModule, keyVaultModule ]
//   params: {
//     catalogConnectionSecretRef: sqlModule.outputs.secretCatalogConnStringRef
//     identityConnSecretRef: sqlModule.outputs.identityConnSecretRef
//     containerRegistryName: containerRegistryName
//     deploymentPrefix: deploymentPrefix
//     imageWebName: imageWebName
//     location: location
//     webAppSku: webAppSku
//     keyVaultKeysPermissions: keyVaultKeysPermissions
//     keyVaultName: keyVaultName
//     keyVaultSecretsPermissions: keyVaultSecretsPermissions
//     webAppName: webAppName
//     serviceBusConnStrRef: serviceBusModule.outputs.serviceBusConnStrRef
//     serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
//     orderItemsResFunctionUrlSecretRef: orderItemsReserverFunctionModule.outputs.orderItemsResFunctionUrlSecretRef
//     appInsightsConnRef: appInsightsModule.outputs.appInsightsConnRef
//   }
// }
