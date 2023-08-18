az group create --name Databases5RG --location "westeurope" 
az deployment group create --resource-group Databases5RG --template-file ./5_Databases/Task/deploy.bicep 
#az deployment group create --resource-group Databases5RG --template-file ./5_Databases/Task/fuction.bicep

