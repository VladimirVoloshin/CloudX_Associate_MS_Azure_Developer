# RUN ALL CONTAINERS FROM ROOT (folder with .sln file):
# docker-compose build
# docker-compose up
#
# RUN JUST THIS CONTAINER FROM ROOT (folder with .sln file):
# docker build --pull -t web -f src/Web/Dockerfile .
#
# RUN COMMAND
#  docker run --name eshopweb --rm -it -p 5106:5106 web
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app/eshopOnWeb

COPY *.sln .
COPY . .
WORKDIR /app/eshopOnWeb/src/Web
RUN dotnet restore

RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS runtime
WORKDIR /app/eshopOnWeb
COPY --from=build /app/eshopOnWeb/src/Web/out ./

# Optional: Set this here if not setting it from docker-compose.yml
# ENV ASPNETCORE_ENVIRONMENT Development

ENTRYPOINT ["dotnet", "Web.dll"]
