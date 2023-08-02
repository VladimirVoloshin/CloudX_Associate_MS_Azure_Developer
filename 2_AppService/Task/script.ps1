az group create --name AppService2RG --location "westeurope" &&
az deployment group create --resource-group AppService2RG --template-file ./2_AppService/Task/sql.bicep
az deployment group create --resource-group AppService2RG --template-file ./2_AppService/Task/publicApi.bicep
az deployment group create --resource-group AppService2RG --template-file ./2_AppService/Task/web.bicep
