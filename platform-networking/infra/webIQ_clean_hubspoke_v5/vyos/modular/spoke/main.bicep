targetScope = 'subscription'

param resourceGroupName string
param location string = 'eastus2'
param vnetName string
param addressSpace array
param workloadSubnetPrefix string
param testVmName string = 'vm-test'
param testVmAdminUsername string = 'azureuser'
param testVmSshPublicKey string
param testVmSize string = 'Standard_B1ms'
param deployTestVm bool = true
param deployTestVmPublicIp bool = false
param adminSourcePrefix string
param enableTransitRouting bool = false
param transitNextHopIp string = ''
param tags object = {
  workload: 'spoke'
  owner: 'webIQ'
}

module rg '../../../shared/modules/foundation/resource-group.bicep' = {
  name: 'spoke-rg'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

module spokeNetwork '../../../shared/modules/network/spoke-vnet.bicep' = {
  name: 'spoke-network'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [ rg ]
  params: {
    vnetName: vnetName
    addressSpace: addressSpace
    workloadSubnetPrefix: workloadSubnetPrefix
    enableTransitRouting: enableTransitRouting
    transitNextHopIp: transitNextHopIp
    tags: tags
  }
}

module testVm '../../../shared/modules/compute/hardened-test-vm.bicep' = if (deployTestVm) {
  name: 'spoke-test-vm'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [ spokeNetwork ]
  params: {
    vmName: testVmName
    subnetId: spokeNetwork.outputs.workloadSubnetId
    adminUsername: testVmAdminUsername
    sshPublicKey: testVmSshPublicKey
    vmSize: testVmSize
    deployPublicIp: deployTestVmPublicIp
    adminSourcePrefix: adminSourcePrefix
    tags: tags
  }
}

output spokeVnetId string = spokeNetwork.outputs.vnetId
output spokeVnetName string = spokeNetwork.outputs.vnetName
output workloadSubnetId string = spokeNetwork.outputs.workloadSubnetId
