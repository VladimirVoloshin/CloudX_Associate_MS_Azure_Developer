$location = 'westeurope'
$resourceGroupName = 'Messaging7RG'
$orderItemsReserverImageName = 'ordritemsres'
$imageWebName = 'web1linux'
$gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer.git'
$gitBranch = 'messaging'
$gitAccessToken = $Env:GITHUB_TOKEN
$webAppDockerFilePath = 'eShopOnWeb\src\Web\Dockerfile'
################################
# CREATE RESOURCE GROUP
################################
az group create --name $resourceGroupName --location $location 

################################
# CREATE RESOURCES
################################
$result = (az deployment group create `
        --resource-group $resourceGroupName `
        --template-file ./7_Messaging/Scripts/main.bicep `
        --parameters ./7_Messaging/Scripts/deployParameters.json orderItemsReserverImageName=$orderItemsReserverImageName imageWebName=$imageWebName) | ConvertFrom-Json
$containerRegistryName = $result.properties.outputs.containerRegistryName.value
$webAppName = $result.properties.outputs.webAppName.value

###############################
#BUILD AND PUSH CONTAINER TO ACR
################################
Set-Location .\eShopOnWeb
docker build --pull --rm -f "src\OrderItemsReserver\Dockerfile" -t $orderItemsReserverImageName .
docker tag "$orderItemsReserverImageName" "$containerRegistryName.azurecr.io/$($orderItemsReserverImageName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($orderItemsReserverImageName):latest"
Set-Location ..

docker build --pull --rm -f "src\Web\Dockerfile" -t $imageWebName .
docker tag "$imageWebName" "$containerRegistryName.azurecr.io/$($imageWebName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imageWebName):latest"

############################################
# CREATE TASKS FOR CONTAINERS
############################################
az acr task create `
    --registry $containerRegistryName `
    --name buildwebApp `
    --image "$($imageWebName):latest" `
    --context "$($gitRepoUrl)#$($gitBranch)" `
    --file $webAppDockerFilePath `
    --git-access-token $gitAccessToken


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


