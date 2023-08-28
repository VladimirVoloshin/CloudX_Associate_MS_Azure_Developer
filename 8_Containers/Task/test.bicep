param location string = 'westeurope'

// define unique service names  
var webAppName = 'webbApp${uniqueString(resourceGroup().id)}'
var webAppServicePlanName = 'webbAppServicePlan${uniqueString(resourceGroup().id)}'
var webSiteName = toLower(webAppName)
var containerRegistryName = 'containterregistry${uniqueString(resourceGroup().id)}'

// variables  
var containerImage = 'compressor/minimal'
var linuxFxVersion = 'DOCKER|${buildContainerImage.outputs.acrImage}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// resource webAppServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
//   name: webAppServicePlanName
//   location: location
//   properties: {
//     reserved: true
//   }
//   sku: {
//     tier: 'Free'
//     name: 'F1'
//   }
//   kind: 'linux'
// }

// resource webApp 'Microsoft.Web/sites@2022-03-01' = {
//   name: webSiteName
//   location: location
//   properties: {
//     reserved: true
//     serverFarmId: webAppServicePlan.id
//     httpsOnly: true
//     clientAffinityEnabled: false
//     siteConfig: {
//       linuxFxVersion: linuxFxVersion
//       ftpsState: 'FtpsOnly'
//       http20Enabled: true
//       minTlsVersion: '1.2'
//       appSettings: [
//         {
//           name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
//           value: 'false'
//         }
//         {
//           name: 'DOCKER_REGISTRY_SERVER_URL'
//           value: 'https://${containerRegistry.name}.azurecr.io'
//         }
//         {
//           name: 'DOCKER_REGISTRY_SERVER_USERNAME'
//           value: containerRegistry.name
//         }
//         {
//           name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
//           value: listCredentials(containerRegistry.id, containerRegistry.apiVersion).passwords[0].value
//         }
//         {
//           name: 'WEBSITES_PORT'
//           value: '8080'
//         }
//       ]
//     }
//   }
// }

module buildContainerImage 'br/public:deployment-scripts/build-acr:1.0.1' = {
  name: 'buildContainerImage'
  params: {
    AcrName: containerRegistry.name
    location: location
    gitRepositoryUrl: 'https://github.com/Azure-Samples/dotnetcore-docs-hello-world'
    gitRepoDirectory: '.'
    imageName: containerImage
  }
}
