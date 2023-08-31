$location = 'westeurope'
$resourceGroupName = 'Messaging7RG'
$orderItemsReserverImageName = 'ordritemsres'
$imageWebName = 'web1linux'

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
# Set-Location .\eShopOnWeb
# docker build --pull --rm -f "src\OrderItemsReserver\Dockerfile" -t $orderItemsReserverImageName .
# docker tag "$orderItemsReserverImageName" "$containerRegistryName.azurecr.io/$($orderItemsReserverImageName):latest"
# az acr login -n $containerRegistryName
# docker push "$containerRegistryName.azurecr.io/$($orderItemsReserverImageName):latest"
# Set-Location ..

# docker build --pull --rm -f "src\Web\Dockerfile" -t $imageWebName .
# docker tag "$imageWebName" "$containerRegistryName.azurecr.io/$($imageWebName):latest"
# az acr login -n $containerRegistryName
# docker push "$containerRegistryName.azurecr.io/$($imageWebName):latest"


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


# az acr webhook create `
#         --name "web1linuxCD" `
#         --registry "messaging20230830registry" `
#         --resource-group "Messaging7RG" `
#         --actions push `
#         --uri "https://$messaging20230830-web-app:LiyzwDJSdemcSGhSEscQqqytpGuLoiYg4yu2Pqf9b7y1dJlgK7qYzqN67lLg@messaging20230830-web-app.scm.azurewebsites.net/api/registry/webhook" `
#         --scope "web1linux:latest"


#         $(az webapp deployment container config --name $webAppName --resource-group $resourceGroupName --enable-cd true --query CI_CD_URL --output tsv)