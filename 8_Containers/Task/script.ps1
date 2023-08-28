$location = 'westeurope'
$resourceGroupName = 'Containers8RG'
$containerRegistryName = 'acrcontainerreg20230826'
$imageWebName = 'web1linux'
$imagePublicApiName = 'publicapilinux'

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
Set-Location ./eshopOnWeb
docker build --pull --rm -f "src\Web\Dockerfile" -t $imageWebName .
docker tag "$imageWebName" "$containerRegistryName.azurecr.io/$($imageWebName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imageWebName):latest"
Set-Location ..

################################
# BUILD AND PUSH CONTAINER TO ACR FOR PublicApi APP
#################################
Set-Location ./eshopOnWeb
docker build --pull --rm -f "src\PublicApi\Dockerfile" -t $imagepublicApiName .
docker tag "$imagepublicApiName" "$containerRegistryName.azurecr.io/$($imagepublicApiName):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imagepublicApiName):latest"
Set-Location ..

