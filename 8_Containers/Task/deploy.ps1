$location = 'westeurope'
$resourceGroupName = 'Containers8RG'
az group create --name $resourceGroupName --location $location 
az deployment group create --resource-group $resourceGroupName --template-file ./8_Containers/Task/deploy.bicep --parameters ./8_Containers/Task/deployParameters.json

