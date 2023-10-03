$location = 'northeurope'
$resourceGroupName = 'Final10RG'
$orderItemsReserverImageName = 'orderitemsreserver'
$imageWebName = 'webapp'
$publicApiImageName = 'publicapi'
$deliveryOrderProcessorImageName = 'deliveryorderprocessor'
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
                --parameters ./10_final/Deployment/deployParameters.json `
                imageWebName=$imageWebName orderItemsReserverImageName=$orderItemsReserverImageName `
                publicApiImageName=$publicApiImageName deliveryOrderProcessorImageName=$deliveryOrderProcessorImageName) | ConvertFrom-Json
$containerRegistryName = $result.properties.outputs.containerRegistryName.value
$webAppName = $result.properties.outputs.webAppName.value
$publicApiName = $result.properties.outputs.publicApiName.value
$orderResFunName = $result.properties.outputs.orderResFunName.value

################################
# BUILD AND PUSH CONTAINER TO ACR FOR WEB APP
#################################
docker build --pull --rm -f "src\Web\Dockerfile" -t $imageWebName .
docker tag "$imageWebName" "$containerRegistryName.azurecr.io/$($imageWebName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imageWebName):latest"

docker build --pull --rm -f "src\PublicApi\Dockerfile" -t $publicApiImageName .
docker tag "$publicApiImageName" "$containerRegistryName.azurecr.io/$($publicApiImageName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($publicApiImageName):latest"

docker build --pull --rm -f "src\OrderItemsReserver\Dockerfile" -t $orderItemsReserverImageName .
docker tag "$orderItemsReserverImageName" "$containerRegistryName.azurecr.io/$($orderItemsReserverImageName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($orderItemsReserverImageName):latest"


############################################
# CREATE WEBHOOKS FOR CONTAINERS
############################################
az acr webhook create `
        --name "$($imageWebName)CD" `
        --registry $containerRegistryName `
        --resource-group $resourceGroupName `
        --actions push `
        --uri $(az webapp deployment container config --name $webAppName --resource-group $resourceGroupName --enable-cd true --query CI_CD_URL --output tsv) `
        --scope "$($imageWebName):latest"

az acr webhook create `
        --name "$($publicApiImageName)CD" `
        --registry $containerRegistryName `
        --resource-group $resourceGroupName `
        --actions push `
        --uri $(az webapp deployment container config --name $publicApiName --resource-group $resourceGroupName --enable-cd true --query CI_CD_URL --output tsv) `
        --scope "$($publicApiImageName):latest"

az acr webhook create `
        --name "$($orderItemsReserverImageName)CD" `
        --registry $containerRegistryName `
        --resource-group $resourceGroupName `
        --actions push `
        --uri $(az webapp deployment container config --name $orderResFunName --resource-group $resourceGroupName --enable-cd true --query CI_CD_URL --output tsv) `
        --scope "$($orderItemsReserverImageName):latest"


# ############################################
# # CREATE TASKS FOR CONTAINERS
# ############################################
az acr task create `
        --registry $containerRegistryName `
        --name buildwebApp `
        --image "$($imageWebName):latest" `
        --context "$($gitRepoUrl)#$($gitBranch)" `
        --file $webAppDockerFilePath `
        --git-access-token $gitAccessToken

az acr task create `
        --registry $containerRegistryName `
        --name buildPublicApiApp `
        --image "$($publicApiImageName):latest" `
        --context "$($gitRepoUrl)#$($gitBranch)" `
        --file $publicApiAppDockerFilePath `
        --git-access-token $gitAccessToken

az acr task create `
        --registry $containerRegistryName `
        --name buildOrderResFunction `
        --image "$($orderItemsReserverImageName):latest" `
        --context "$($gitRepoUrl)#$($gitBranch)" `
        --file $orderReservFunAppDockerFilePath `
        --git-access-token $gitAccessToken
