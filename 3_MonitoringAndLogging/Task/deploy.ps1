az group create --name AppService3RG --location "westeurope" &&
az deployment group create --resource-group AppService3RG --template-file ./3_MonitoringAndLogging/Task/sql.bicep
az deployment group create --resource-group AppService3RG --template-file ./3_MonitoringAndLogging/Task/publicApi.bicep
