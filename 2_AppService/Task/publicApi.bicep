param deploymentId string = '20233007'
param webAppName string = 'PublicApi-${deploymentId}'
param location string = resourceGroup().location
param sku string = 'P1v2'
var appServicePlanName = 'AppServicePlan-${webAppName}-${deploymentId}'
var gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer'
//var gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer/eShopOnWeb/src/PublicApi'
param serverName string = 'sql-eShopOnWeb-${deploymentId}'
param catalogDb string = 'CatalogDb'
param identity string = 'Identity'
param administratorLogin string = 'sqlUser'
@secure()
param administratorLoginPassword string = 'as##J98f!44'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
}

resource autoscaling 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'Autoscale-${webAppName}'
  location: location
  tags: {}
  properties: {
    enabled: true
    targetResourceUri: '/subscriptions/32de0203-f852-40a8-87b2-611e68a7e808/resourceGroups/AppService2RG/providers/Microsoft.Web/serverFarms/${appServicePlanName}'
    profiles: [
      {
        name: 'Auto created default scale condition'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: '/subscriptions/32de0203-f852-40a8-87b2-611e68a7e808/resourceGroups/AppService2RG/providers/Microsoft.Web/serverFarms/${appServicePlanName}'
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 50
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dimensions: []
              dividePerInstance: false
            }
          }
          {
              scaleAction: {
                direction: 'Decrease'
                type: 'ChangeCount'
                value: '1'
                cooldown: 'PT5M'
              }
              metricTrigger: {
                metricName: 'CpuPercentage'
                metricNamespace: 'microsoft.web/serverfarms'
                metricResourceUri: '/subscriptions/32de0203-f852-40a8-87b2-611e68a7e808/resourceGroups/AppService2RG/providers/Microsoft.Web/serverFarms/${appServicePlanName}'
                operator: 'LessThan'
                statistic: 'Average'
                threshold: 20
                timeAggregation: 'Average'
                timeGrain: 'PT1M'
                timeWindow: 'PT1M'
                dimensions: []
                dividePerInstance: false
              }
            }          
        ]
      }
    ]
    notifications: []
    targetResourceLocation: 'West Europe'
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
    }
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

// resource gitsource 'Microsoft.Web/sites/sourcecontrols@2022-03-01' = {
//   parent: webApp
//   name: 'web'
//   properties: {
//     repoUrl: gitRepoUrl
//     branch: 'master'
//     isManualIntegration: true
//   }
// }


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
