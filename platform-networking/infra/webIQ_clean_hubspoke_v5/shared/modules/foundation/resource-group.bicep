targetScope = 'subscription'

@description('Name of the resource group to create.')
param resourceGroupName string

@description('Azure region for the resource group.')
param location string

@description('Tags to apply to the resource group.')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

output resourceGroupName string = rg.name
output resourceGroupId string = rg.id
