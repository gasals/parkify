# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore "parkify.API/parkify.API.csproj"
WORKDIR "/src/parkify.API"
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
EXPOSE 5050
ENV ASPNETCORE_URLS=http://+:5050
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "parkify.API.dll"]