targetScope = 'subscription'

param resourceGroupName string = 'rg-webiq-vsrx-hub'
param location string = 'eastus2'
param vnetName string = 'vnet-webiq-vsrx-hub'
param addressSpace array = [ '10.60.0.0/16' ]
param nvaSubnetPrefix string = '10.60.1.0/24'
param nvaPrivateIp string = '10.60.1.4'
param nvaVmName string = 'vsrx-hub'
param nvaAdminUsername string = 'azureuser'
@secure()
param nvaAdminPassword string
param nvaVmSize string = 'Standard_D3_v2'
param adminSourcePrefix string
param tags object = {
  workload: 'hub'
  nvaVendor: 'vSRX'
  owner: 'webIQ'
}

module rg '../../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vsrx-hub-rg'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

module hubNetwork '../../../shared/modules/network/hub-vnet.bicep' = {
  name: 'vsrx-hub-network'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [ rg ]
  params: {
    vnetName: vnetName
    addressSpace: addressSpace
    nvaSubnetPrefix: nvaSubnetPrefix
    tags: tags
  }
}

module nva '../../../shared/modules/nva/vsrx-nva.bicep' = {
  name: 'vsrx-hub-nva'
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
