targetScope='subscription'

param resourceGroupName string = 'AppService2RG'
param resourceGroupLocation string = 'westeurope'

resource mainResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}
