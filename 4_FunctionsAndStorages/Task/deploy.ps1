az group create --name FunctionsAndStorages4RG --location "westeurope" 
az deployment group create --resource-group FunctionsAndStorages4RG --template-file ./4_FunctionsAndStorages/Task/fuction.bicep
#az deployment group create --resource-group FunctionsAndStorages4RG --template-file ./4_FunctionsAndStorages/Task/sql.bicep
#az deployment group create --resource-group FunctionsAndStorages4RG --template-file ./4_FunctionsAndStorages/Task/publicApi.bicep
