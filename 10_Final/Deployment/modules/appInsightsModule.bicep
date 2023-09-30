param location string
param appInsightsName string
param appInsightsProjName string
param keyVaultName string
param appInsightsConnStrSecretName string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'app'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: appInsightsName
  location: location
  tags: {
    displayName: 'Log Analytics'
    ProjectName: appInsightsProjName
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource secretAppInsightsConnStringRes 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: keyVaultRef
  name: appInsightsConnStrSecretName
  properties: {
    value: appInsights.properties.ConnectionString
  }
}

output appInsightsConnRef string = '@Microsoft.KeyVault(SecretUri=${reference(appInsightsConnStrSecretName).secretUriWithVersion})'
