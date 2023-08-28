$location = 'westeurope'
$resourceGroupName = 'Containers8RG'
$containerRegistryName = 'acrcontainerreg20230826'
$webAppName = 'web-containers-APP'
$publicApiName = 'publicApi-containers-APP'
$imageWebName = 'web1linux'
$imagePublicApiName = 'publicapilinux'
$gitRepoUrl = 'https://github.com/VladimirVoloshin/CloudX_Associate_MS_Azure_Developer.git'
$gitBranch = 'master'
$webAppDockerFilePath = 'eShopOnWeb\src\Web\Dockerfile'
$publicApiAppDockerFilePath = 'eShopOnWeb\src\PublicApi\Dockerfile'
$gitAccessToken = $Env:GITHUB_TOKEN


################################
# CREATE RESOURCE GROUP
################################
az group create --name $resourceGroupName --location $location 

################################
# CREATE RESOURCES
################################
az deployment group create --resource-group $resourceGroupName `
    --template-file ./8_Containers/Task/deploy.bicep `
    --parameters ./8_Containers/Task/deployParameters.json containerRegistryName=$containerRegistryName imageWebName=$imageWebName imagePublicApiName=$imagePublicApiName

################################
# BUILD AND PUSH CONTAINER TO ACR FOR WEB APP
#################################
docker build --pull --rm -f "src\Web\Dockerfile" -t $imageWebName .
docker tag "$imageWebName" "$containerRegistryName.azurecr.io/$($imageWebName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imageWebName):latest"

docker build --pull --rm -f "src\PublicApi\Dockerfile" -t $imagepublicApiName .
docker tag "$imagepublicApiName" "$containerRegistryName.azurecr.io/$($imagepublicApiName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imagepublicApiName):latest"

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
    --name "$($imagePublicApiName)CD" `
    --registry $containerRegistryName `
    --resource-group $resourceGroupName `
    --actions push `
    --uri $(az webapp deployment container config --name $publicApiName --resource-group $resourceGroupName --enable-cd true --query CI_CD_URL --output tsv) `
    --scope "$($imagePublicApiName):latest"

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
    --image "$($imagePublicApiName):latest" `
    --context "$($gitRepoUrl)#$($gitBranch)" `
    --file $publicApiAppDockerFilePath `
    --git-access-token $gitAccessToken