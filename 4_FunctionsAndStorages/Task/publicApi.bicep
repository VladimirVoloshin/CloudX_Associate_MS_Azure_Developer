param deploymentId string = '20233007'
param webAppName string = 'PublicApi-${deploymentId}'
param location string = resourceGroup().location
param sku string = 'S1'
var appServicePlanName = 'AppServicePlan-${webAppName}-${deploymentId}'
var gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
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
        {
          name: 'project'
          value: 'eShopOnWeb/src/PublicApi/PublicApi.csproj'
        }
        {
          name:'ASPNETCORE_ENVIRONMENT'
          value:'Production'
        }
      ]
    }
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

resource gitsource 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
  parent: webApp
  name: 'web'
  properties: {
    repoUrl: gitRepoUrl
    branch: 'master'
    isManualIntegration: true
  }
}

