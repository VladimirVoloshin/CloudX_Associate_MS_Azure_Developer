param deploymentPrefix string
param cosmosAccountName string = '${deploymentPrefix}delorderprocesdb'
param location string
param keyVaultName string
param cosmosDbConnStringName string = 'cosmosdbConnectionStringName'
var databaseName = 'deliverorderprocessordb${deploymentPrefix}'
var containerName = 'orders'

resource account 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: toLower(cosmosAccountName)
  location: location
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: databaseName
  parent: account
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 1000
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/delivery'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
    }
  }
}

resource keyVaultRef 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource secretCatalogConnStringRes 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVaultRef
  name: cosmosDbConnStringName
  properties: {
    value: account.listConnectionStrings().connectionStrings[0].connectionString
  }
}

output cosmoDbConnStringRef string = '@Microsoft.KeyVault(SecretUri=${reference(cosmosDbConnStringName).secretUriWithVersion})'
output accountName string = account.name
output databaseName string = database.name
output containerName string = container.name
