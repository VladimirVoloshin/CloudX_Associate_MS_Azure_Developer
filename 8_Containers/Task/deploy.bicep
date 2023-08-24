param location string = resourceGroup().location
var tenantId = subscription().tenantId
param gitRepoUrl string
param branch string
param netFrameworkVersion string
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

// KEY VAULT START
resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  dependsOn: [ webApp ]
  properties: {
    tenantId: tenantId
    enablePurgeProtection: null
    enableSoftDelete: false
    accessPolicies: [
      {
        objectId: webApp.identity.principalId
        tenantId: tenantId
        permissions: {
          keys: keyVaultKeysPermissions
          secrets: keyVaultSecretsPermissions
        }
      }
      {
        objectId: publicApiApp.identity.principalId
        tenantId: tenantId
        permissions: {
          keys: keyVaultKeysPermissions
          secrets: keyVaultSecretsPermissions
        }
      }
    ]
    sku: {
      name: keyVaultSku
      family: 'A'
    }
  }
}

resource secretCatalogConnString 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: catalogConnectionSecretName
  properties: {
    value: 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${catalogDbName} ;Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}
resource secretIdentityConnString 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  parent: kv
  name: identityConnectionSecretName
  properties: {
    value: 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${identityDBName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

// KEY VAULT END

// WEB START
resource webAppServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: webAppServicePlanName
  location: location
  sku: {
    name: webAppSku
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'project'
          value: 'eShopOnWeb/src/Web/Web.csproj'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'OrderItemsReserver__Url'
          value: ''
        }
        {
          name: 'OrderItemsReserver__IsEnabled'
          value: 'false'
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
          name: 'MSBuildSDKsPath'
          value: 'C:\\Program Files (x86)\\dotnet\\sdk\\7.0.305\\Sdks'
        }
      ]
      netFrameworkVersion: netFrameworkVersion
    }
    serverFarmId: webAppServicePlan.id
    httpsOnly: true
  }
}

resource connectionstringsWeb 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'connectionstrings'
  parent: webApp
  dependsOn: [
    kv
  ]
  properties: {
    CatalogConnection: {
      value: '@Microsoft.KeyVault(SecretUri=${reference(catalogConnectionSecretName).secretUriWithVersion})'
      type: 'SQLServer'
    }
    IdentityConnection: {
      value: '@Microsoft.KeyVault(SecretUri=${reference(identityConnectionSecretName).secretUriWithVersion})'
      type: 'SQLServer'
    }
  }
}

resource gitsourceWebApp 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: webApp
  name: 'web'
  properties: {
    repoUrl: gitRepoUrl
    branch: branch
    isManualIntegration: true
  }
}
// WEB END

// PUBLIC API START
resource publicApiAppServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: publicApiAppServicePlanName
  location: location
  sku: {
    name: publicApiSku
  }
}

resource publicApiApp 'Microsoft.Web/sites@2022-03-01' = {
  name: publicApiAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'project'
          value: 'eShopOnWeb/src/PublicApi/PublicApi.csproj'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
    serverFarmId: publicApiAppServicePlan.id
    httpsOnly: true
  }
}

resource gitsourcePublicApi 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: publicApiApp
  name: 'web'
  properties: {
    repoUrl: gitRepoUrl
    branch: branch
    isManualIntegration: true
  }
}
// PUBLIC API END

// SQL Server start
resource sqlServerInstance 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPass
  }
}

resource SQLAllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2020-11-01-preview' = {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServerInstance
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource catalogDb_database 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  parent: sqlServerInstance
  name: catalogDbName
  location: location
  sku: {
    name: 'GP_S_Gen5_1'
  }
  properties: {
    autoPauseDelay: 60
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    minCapacity: 1
  }
}

resource identity_database 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  parent: sqlServerInstance
  name: identityDBName
  location: location
  sku: {
    name: 'GP_S_Gen5_1'
  }
  properties: {
    autoPauseDelay: 60
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    minCapacity: 1
  }
}
//SQL Server End
