targetScope = 'resourceGroup'

@description('Hub VNet name.')
param vnetName string

@description('Hub VNet address spaces.')
param addressSpace array

@description('Name of the NVA subnet.')
param nvaSubnetName string = 'NvaSubnet'

@description('Address prefix for the NVA subnet.')
param nvaSubnetPrefix string

@description('Tags to apply.')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressSpace
    }
    subnets: [
      {
        name: nvaSubnetName
        properties: {
          addressPrefix: nvaSubnetPrefix
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output nvaSubnetId string = '${vnet.id}/subnets/${nvaSubnetName}'
