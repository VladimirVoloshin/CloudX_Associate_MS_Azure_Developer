$containerRegistryName = 'acrcontainerreg20230826'
$imageTag = 'web1linux'
Set-Location ..\..\..\Repository\eShopOnWeb
docker build --pull --rm -f "src\Web\Dockerfile" -t $imageTag .
docker tag "$imageTag" "$containerRegistryName.azurecr.io/$($imageTag):latest"
az acr login -n $containerRegistryName
docker push "$containerRegistryName.azurecr.io/$($imageTag):latest"
Set-Location ..
