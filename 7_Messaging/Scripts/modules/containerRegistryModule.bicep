param containerRegistryName string
param location string
param acrSku string

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
  }
}

output containerRegistryId string = acrResource.id
output containerRegistryName string = acrResource.name
output containerRegistryLoginServer string = acrResource.properties.loginServer
