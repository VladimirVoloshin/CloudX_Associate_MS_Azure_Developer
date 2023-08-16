param deploymentId string = '20231508'
param appName string = 'OrderItemsReserver-${deploymentId}'
param storageAccountType string = 'Standard_LRS'
param location string = resourceGroup().location
var gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer'
param webAppServicePlanName string = 'web-1-${deploymentId}'
param webAppName string = 'web-${deploymentId}'
param sku string = 'S1'
param serverName string = 'sql-eShopOnWeb-${deploymentId}'
param catalogDb string = 'CatalogDb'
param identity string = 'Identity'
param administratorLogin string = 'sqlUser'
@secure()
param administratorLoginPassword string = 'as##J98f!44'

param runtime string = 'dotnet'

var functionAppName = appName
var hostingPlanName = appName
var storageAccountName = 'orderitemsres${deploymentId}'
var functionWorkerRuntime = runtime

// STORAGE ACCOUNT START
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}
// STORAGE ACCOUNT END

// FUNCTION START
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'ContainerName'
          value: 'order-upload'
        }
        {
          name: 'project'
          value: 'eShopOnWeb/src/OrderItemsReserver/OrderItemsReserver.csproj'
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource gitsourceFunction 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    repoUrl: gitRepoUrl
    branch: 'master'
    isManualIntegration: true
  }
}
// FUNCTION END

// WEB START
resource webAppServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: webAppServicePlanName
  location: location
  sku: {
    name: sku
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
        // {
        //   name: 'project'
        //   value: 'eShopOnWeb/src/Web/Web.csproj'
        // }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'CONNECTION_STRINGS_CATALOG_CONNECTION'
          value: 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${catalogDb};Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'CONNECTION_STRINGS_IDENTITY_CONNECTION'
          value: 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${identity};Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'ORDER_ITEMS_RESERVER_URL'
          value: 'https://${functionAppName}.azurewebsites.net//api/OrderItemsReserverFunction?code=${storageAccount.listKeys().keys[0]}'
        }
      ]
      connectionStrings: [
        {
          name: 'CatalogConnection'
          connectionString: 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${catalogDb};Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLAzure'
        }
        {
          name: 'IdentityConnection'
          connectionString: 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${identity};Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLAzure'
        }
      ]
    }
    serverFarmId: webAppServicePlan.id
    httpsOnly: true
  }
}

// resource gitsourceWebApp 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
//   parent: webApp
//   name: 'web'
//   properties: {
//     repoUrl: gitRepoUrl
//     branch: 'master'
//     isManualIntegration: true
//   }
// }
// WEB END

// SQL Server start
resource sqlServerInstance 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
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
  name: catalogDb
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
  name: identity
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
