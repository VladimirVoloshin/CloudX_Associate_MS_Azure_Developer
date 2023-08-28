param location string = resourceGroup().location
param serverName string
param catalogDbName string
param identityDBName string
param sqlAdminLogin string
@secure()
param sqlAdminPass string

resource sqlServerInstance 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPass
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
  name: catalogDbName
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
  name: identityDBName
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

output catalogDbConnString string = 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${catalogDbName} ;Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
output identityDbConnString string = 'Server=tcp:${serverName}.database.windows.net,1433;Initial Catalog=${identityDBName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPass};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
