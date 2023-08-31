param location string
param deploymentPrefix string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${deploymentPrefix}-web-identity'
  location: location
}

output webAppManagedIdentityId string = managedIdentity.properties.principalId
output webAppManagedIdentityResId string = managedIdentity.id
