$location = 'northeurope'
$resourceGroupName = 'Final10RG'
$orderItemsReserverImageName = 'orderitemsreserver'
$imageWebName = 'web1linux'
$gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer.git'
$gitBranch = 'messaging'
$gitAccessToken = $Env:GITHUB_TOKEN
$webAppDockerFilePath = 'eShopOnWeb\src\Web\Dockerfile'
$orderReservFunAppDockerFilePath = 'eShopOnWeb\src\OrderItemsReserver\Dockerfile'
################################
# CREATE RESOURCE GROUP
################################
az group create --name $resourceGroupName --location $location 

################################
# CREATE RESOURCES
################################
$result = (az deployment group create `
                --resource-group $resourceGroupName `
                --template-file ./10_final/Deployment/main.bicep `
                --parameters ./10_final/Deployment/deployParameters.json) | ConvertFrom-Json
$containerRegistryName = $result.properties.outputs.containerRegistryName.value
$webAppName = $result.properties.outputs.webAppName.value
$orderResFunName = $result.properties.outputs.orderResFunName.value



