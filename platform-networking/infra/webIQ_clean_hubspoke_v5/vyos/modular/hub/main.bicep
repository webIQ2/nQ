targetScope = 'subscription'

param resourceGroupName string = 'rg-webiq-vyos-hub'
param location string = 'eastus2'
param vnetName string = 'vnet-webiq-vyos-hub'
param addressSpace array = [ '10.60.0.0/16' ]
param nvaSubnetPrefix string = '10.60.1.0/24'
param nvaPrivateIp string = '10.60.1.4'
param nvaVmName string = 'vyos-hub'
param nvaAdminUsername string = 'vyos'
@secure()
param nvaAdminPassword string
param nvaVmSize string = 'Standard_B2ms'
param adminSourcePrefix string
param tags object = {
  workload: 'hub'
  nvaVendor: 'VyOS'
  owner: 'webIQ'
}

module rg '../../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vyos-hub-rg'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

module hubNetwork '../../../shared/modules/network/hub-vnet.bicep' = {
  name: 'vyos-hub-network'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [ rg ]
  params: {
    vnetName: vnetName
    addressSpace: addressSpace
    nvaSubnetPrefix: nvaSubnetPrefix
    tags: tags
  }
}

module nva '../../../shared/modules/nva/vyos-nva.bicep' = {
  name: 'vyos-hub-nva'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [ hubNetwork ]
  params: {
    vmName: nvaVmName
    subnetId: hubNetwork.outputs.nvaSubnetId
    privateIpAddress: nvaPrivateIp
    adminUsername: nvaAdminUsername
    adminPassword: nvaAdminPassword
    vmSize: nvaVmSize
    adminSourcePrefix: adminSourcePrefix
    tags: tags
  }
}

output hubVnetId string = hubNetwork.outputs.vnetId
output hubVnetName string = hubNetwork.outputs.vnetName
output nvaPrivateIp string = nva.outputs.privateIp
output nvaPublicIp string = nva.outputs.publicIp
