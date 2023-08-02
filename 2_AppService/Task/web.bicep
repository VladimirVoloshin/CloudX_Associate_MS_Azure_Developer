param deploymentId string = '20230208'
param traficManagerDnsName string = 'web-tm-${deploymentId}'
param webAppName string = 'web-1-${deploymentId}'
param webAppName2 string = 'web-2-${deploymentId}'
param location string = resourceGroup().location
param location2 string = 'southcentralus'
param sku string = 'P1v2'
var appServicePlanName = 'AppServicePlan-1-${webAppName}-${deploymentId}'
var appServicePlanName2 = 'AppServicePlan-2-${webAppName}-${deploymentId}'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
}

resource appServicePlan2 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName2
  location: location2
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
    }
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}

resource webApp2 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName2
  location: location2
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
    }
    serverFarmId: appServicePlan2.id
    httpsOnly: true
  }
}

resource webApp1SlotStage 'Microsoft.Web/sites/slots@2022-09-01' = {
  name: '${webAppName}-stage'
  kind: 'webapp'
  location:location
  parent: webApp
  properties:{
    serverFarmId: appServicePlan.id
  }
}

resource webApp2SlotStage 'Microsoft.Web/sites/slots@2022-09-01' = {
  name: '${webAppName2}-stage'
  kind: 'webapp'
  location:location
  parent: webApp
  properties:{
    serverFarmId: appServicePlan2.id
  }
}

resource webTrafficManager 'Microsoft.Network/trafficmanagerprofiles@2018-08-01' = {
  name: 'webTrafficManager'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Geographic'
    dnsConfig: {
      relativeName: traficManagerDnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTPS'
      port: 443
      path: '/'
      expectedStatusCodeRanges: [
        {
          min: 200
          max: 202
        }
        {
          min: 301
          max: 302
        }
      ]
    }
    endpoints: [
      {
        type: 'Microsoft.Network/TrafficManagerProfiles/azureEndpoints'
        name: 'endpoint1'
        properties: {
          targetResourceId: webApp.id
          endpointStatus: 'Enabled'
          geoMapping: [
            'ES'
          ]
        }
      }
      {
        type: 'Microsoft.Network/TrafficManagerProfiles/azureEndpoints'
        name: 'endpoint2'
        properties: {
          targetResourceId: webApp2.id
          endpointStatus: 'Enabled'
          geoMapping: [
            'US'
          ]
        }
      }
    ]
  }
}

