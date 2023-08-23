az group create --name KeyVault6RG --location "westeurope" 
az deployment group create --resource-group KeyVault6RG --template-file ./6_KeyVault/Task/deploy.bicep --parameters ./6_KeyVault/Task/deployParameters.json

