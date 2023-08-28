param location string = resourceGroup().location
param keyVaultName string
param keyVaultKeysPermissions array
param keyVaultSecretsPermissions array
param keyVaultSku string
param catalogConnectionSecretName string
param identityConnectionSecretName string
param publicApiAppServicePlanName string
param publicApiAppName string
param publicApiSku string
param webAppServicePlanName string
param webAppName string
param webAppSku string
param serverName string
param catalogDbName string
param identityDBName string
param sqlAdminLogin string
@secure()
param sqlAdminPass string
param appInsightsName string
param containerRegistryName string
param imageWebName string
param imagePublicApiName string
param acrSku string

module acr './modules/container.bicep' = {
  name: 'farmDeployment'
  params: {
    location: location
    containerRegistryName: containerRegistryName
    acrSku: acrSku
  }
}

module sql './modules/sql.bicep' = {
  name: 'sqlServerAndDbDeployment'
  params: {
    location: location
    serverName: serverName
    catalogDbName: catalogDbName
    identityDBName: identityDBName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPass: sqlAdminPass
  }
}

module webApp './modules/web.bicep' = {
  name: 'webAppDeployment'
  dependsOn: [ acr ]
  params: {
    location: location
    containerRegistryName: containerRegistryName
    imageWebName: imageWebName
    webAppName: webAppName
    webAppSku: webAppSku
    catalogConnString: sql.outputs.catalogDbConnString
    identityConnString: sql.outputs.identityDbConnString
  }
}

module publicApi './modules/publicApi.bicep' = {
  name: 'publicApiAppDeployment'
  dependsOn: [ acr ]
  params: {
    containerRegistryName: containerRegistryName
    imagePublicApiName: imagePublicApiName
    location: location
    publicApiAppName: publicApiAppName
    publicApiAppServicePlanName: publicApiAppServicePlanName
    publicApiSku: publicApiSku
    catalogConnString: sql.outputs.catalogDbConnString
    identityConnString: sql.outputs.identityDbConnString
  }
}
