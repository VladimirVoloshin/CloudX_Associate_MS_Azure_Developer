param location string = resourceGroup().location
param deploymentPrefix string = 'messaging${uniqueString(resourceGroup().id)}'

// acr module
param acrSku string
var containerRegistryName = '${deploymentPrefix}registry'

// key vault module
param keyVaultName string = '${deploymentPrefix}kvault'
param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array
param keyVaultSku string

// sql module
param serverName string
param sqlAdminLogin string
@secure()
param sqlAdminPass string
param catalogConnectionSecretName string
param identityConnectionSecretName string
param catalogDbName string
param identityDBName string

// web module
param imageWebName string
param webAppSku string
param webAppName string = '${deploymentPrefix}-web-app'

// function module
param orderItemsReserverImageName string
param orderResItemsFunctionUrlSecretName string
// storage account module
param storageAccountType string

// service bus
param serviceBusOrderCreatedQueueName string
@secure()
param serviceBusOrderConnNameSecret string

module keyVaultModule 'modules/keyVaultModule.bicep' = {
  name: 'keyVaultModule'
  params: {
    keyVaultSku: keyVaultSku
    location: location
    keyVaultName: keyVaultName
  }
}

module serviceBusModule 'modules/serviceBusModule.bicep' = {
  name: 'ServiceBusModule'
  dependsOn: [ keyVaultModule ]
  params: {
    location: location
    serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
    keyVaultName: keyVaultName
    serviceBusOrderConnNameSecret: serviceBusOrderConnNameSecret
    deploymentPrefix: deploymentPrefix
  }
}

module sqlModule 'modules/sql.bicep' = {
  name: 'sqlModule'
  dependsOn: [ keyVaultModule ]
  params: {
    catalogConnectionSecretName: catalogConnectionSecretName
    catalogDbName: catalogDbName
    identityConnectionSecretName: identityConnectionSecretName
    identityDBName: identityDBName
    keyVaultName: keyVaultName
    serverName: serverName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPass: sqlAdminPass
    location: location
  }
}

module acrModule './modules/containerRegistryModule.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    containerRegistryName: containerRegistryName
    acrSku: acrSku
  }
}

module webAppModule './modules/webAppModule.bicep' = {
  name: 'webApp'
  params: {
    catalogConnectionSecretRef: sqlModule.outputs.secretCatalogConnStringRef
    identityConnSecretRef: sqlModule.outputs.identityConnSecretRef
    containerRegistryName: containerRegistryName
    deploymentPrefix: deploymentPrefix
    imageWebName: imageWebName
    location: location
    webAppSku: webAppSku
    keyVaultKeysPermissions: keyVaultKeysPermissions
    keyVaultName: keyVaultName
    keyVaultSecretsPermissions: keyVaultSecretsPermissions
    webAppName: webAppName
    serviceBusConnStrRef: serviceBusModule.outputs.serviceBusConnStrRef
    serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
    orderItemsResFunctionUrlSecretRef: orderItemsReserverFunctionModule.outputs.orderItemsResFunctionUrlSecretRef
  }
}

module storageAccountModule './modules/storageAccountModule.bicep' = {
  name: 'storageAccountModule'
  params: {
    deploymentPrefix: deploymentPrefix
    location: location
    storageAccountType: storageAccountType
  }
}

module orderItemsReserverFunctionModule './modules/orderItemsReservFunctionModule.bicep' = {
  name: 'orderItemsReserverFunction'
  dependsOn: [ storageAccountModule ]
  params: {
    containerRegistryName: acrModule.outputs.containerRegistryName
    deploymentPrefix: deploymentPrefix
    imageName: orderItemsReserverImageName
    location: location
    storageAccountName: storageAccountModule.outputs.storageAccountName
    serviceBusConnStrRef: serviceBusModule.outputs.serviceBusConnStrRef
    serviceBusOrderCreatedQueueName: serviceBusOrderCreatedQueueName
    keyVaultName: keyVaultName
    orderResItemsFunctionUrlSecretName: orderResItemsFunctionUrlSecretName
  }
}

output containerRegistryName string = containerRegistryName
output webAppName string = webAppName
