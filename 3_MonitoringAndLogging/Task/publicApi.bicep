param deploymentId string = '20233007'
param webAppName string = 'PublicApi-${deploymentId}'
param location string = resourceGroup().location
param sku string = 'S1'
//param sku string = 'P1v2'
var appServicePlanName = 'AppServicePlan-${webAppName}-${deploymentId}'
var gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer'
var appInsightsName = '${webAppName}-insights'
var appInsightsID = resourceId(resourceGroup().name, 'Microsoft.insights/components/', appInsightsName)

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
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
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

// resource autoscaling 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
//   name: 'Autoscale-${webAppName}'
//   location: location
//   tags: {}
//   dependsOn: [ appServicePlan, webApp ]
//   properties: {
//     enabled: true
//     targetResourceUri: '/subscriptions/32de0203-f852-40a8-87b2-611e68a7e808/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/serverFarms/${appServicePlanName}'
//     profiles: [
//       {
//         name: 'Auto created default scale condition'
//         capacity: {
//           minimum: '1'
//           maximum: '10'
//           default: '1'
//         }
//         rules: [
//           {
//             scaleAction: {
//               direction: 'Increase'
//               type: 'ChangeCount'
//               value: '1'
//               cooldown: 'PT1M'
//             }
//             metricTrigger: {
//               metricName: 'CpuPercentage'
//               metricNamespace: 'microsoft.web/serverfarms'
//               metricResourceUri: '/subscriptions/32de0203-f852-40a8-87b2-611e68a7e808/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/serverFarms/${appServicePlanName}'
//               operator: 'GreaterThan'
//               statistic: 'Average'
//               threshold: 50
//               timeAggregation: 'Average'
//               timeGrain: 'PT1M'
//               timeWindow: 'PT5M'
//               dimensions: []
//               dividePerInstance: false
//             }
//           }
//           {
//             scaleAction: {
//               direction: 'Decrease'
//               type: 'ChangeCount'
//               value: '1'
//               cooldown: 'PT5M'
//             }
//             metricTrigger: {
//               metricName: 'CpuPercentage'
//               metricNamespace: 'microsoft.web/serverfarms'
//               metricResourceUri: '/subscriptions/32de0203-f852-40a8-87b2-611e68a7e808/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/serverFarms/${appServicePlanName}'
//               operator: 'LessThan'
//               statistic: 'Average'
//               threshold: 20
//               timeAggregation: 'Average'
//               timeGrain: 'PT1M'
//               timeWindow: 'PT1M'
//               dimensions: []
//               dividePerInstance: false
//             }
//           }
//         ]
//       }
//     ]
//     notifications: []
//     targetResourceLocation: 'West Europe'
//   }
// }

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
    ProjectName: webAppName
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
