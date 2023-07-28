# az deployment sub create -l westeurope  -f ./2_AppService/Task/resourceGroup.bicep
az group create --name AppService2RG --location "westeurope" &&
az deployment group create --resource-group AppService2RG --template-file ./2_AppService/Task/publicApi.bicep
