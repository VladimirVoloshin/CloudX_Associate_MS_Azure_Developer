param containerRegistryName string
param location string

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

output containerRegistryId string = acrResource.id
output containerRegistryName string = acrResource.name
output containerRegistryLoginServer string = acrResource.properties.loginServer
