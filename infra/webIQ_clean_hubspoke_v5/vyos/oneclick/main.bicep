targetScope = 'tenant'

@description('Hub subscription ID (defaults to webIQ Infrastructure).')
param hubSubscriptionId string = '7426560d-ace3-4e95-9df4-69985fb9d8cc'

@description('Commercial spoke subscription ID (defaults to netIQ).')
param commercialSubscriptionId string = 'ff60f646-9751-4074-9f58-9fc310105c4c'

@description('Government spoke subscription ID (defaults to Gi).')
param governmentSubscriptionId string = '1011dd77-657c-4c57-931b-0b77b92e7378'

param hubResourceGroupName string = 'rg-webiq-vyos-hub'
param commercialResourceGroupName string = 'rg-netiq-vyos-commercial'
param governmentResourceGroupName string = 'rg-gi-vyos-government'

param hubLocation string = 'eastus2'
param commercialLocation string = 'eastus2'
param governmentLocation string = 'eastus2'

param hubVnetName string = 'vnet-webiq-vyos-hub'
param commercialVnetName string = 'vnet-netiq-commercial'
param governmentVnetName string = 'vnet-gi-government'

param hubAddressSpace array = [ '10.60.0.0/16' ]
param commercialAddressSpace array = [ '10.61.0.0/16' ]
param governmentAddressSpace array = [ '10.62.0.0/16' ]

param hubNvaSubnetPrefix string = '10.60.1.0/24'
param hubNvaPrivateIp string = '10.60.1.4'
param commercialWorkloadSubnetPrefix string = '10.61.1.0/24'
param governmentWorkloadSubnetPrefix string = '10.62.1.0/24'

param nvaVmName string = 'vyos-hub'
param nvaAdminUsername string = 'vyos'
@secure()
param nvaAdminPassword string
param nvaVmSize string = 'Standard_B2ms'
param adminSourcePrefix string

@description('Deploy the commercial and government test VMs in the one-click stack.')
param deployCommercialTestVm bool = true
param deployGovernmentTestVm bool = true
param testVmAdminUsername string = 'azureuser'
param testVmSshPublicKey string
param commercialTestVmName string = 'vm-commercial-test'
param governmentTestVmName string = 'vm-government-test'
param commercialTestVmSize string = 'Standard_D2s_v3'
param governmentTestVmSize string = 'Standard_D2s_v3'
param deployTestVmPublicIp bool = false

@description('Create explicit opposite-spoke UDRs via the VyOS appliance.')
param enableInterSpokeTransit bool = true

@description('Create a 0.0.0.0/0 route in each spoke toward the VyOS appliance. Keep false for the single-NIC proof-of-concept.')
param enableForcedInternetEgress bool = false

param tags object = {
  workload: 'hub-spoke'
  nvaVendor: 'VyOS'
  owner: 'webIQ'
}

var commercialTransitPrefixes = enableInterSpokeTransit ? governmentAddressSpace : []
var governmentTransitPrefixes = enableInterSpokeTransit ? commercialAddressSpace : []

module hubRg '../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vyos-hub-rg'
  scope: subscription(hubSubscriptionId)
  params: {
    resourceGroupName: hubResourceGroupName
    location: hubLocation
    tags: tags
  }
}

module commercialRg '../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vyos-commercial-rg'
  scope: subscription(commercialSubscriptionId)
  params: {
    resourceGroupName: commercialResourceGroupName
    location: commercialLocation
    tags: tags
  }
}

module governmentRg '../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vyos-government-rg'
  scope: subscription(governmentSubscriptionId)
  params: {
    resourceGroupName: governmentResourceGroupName
    location: governmentLocation
    tags: tags
  }
}

module hubNetwork '../../shared/modules/network/hub-vnet.bicep' = {
  dependsOn: [
    hubRg
  ]
  name: 'vyos-hub-network'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    vnetName: hubVnetName
    addressSpace: hubAddressSpace
    nvaSubnetPrefix: hubNvaSubnetPrefix
    tags: tags
  }
}

module commercialNetwork '../../shared/modules/network/spoke-vnet.bicep' = {
  dependsOn: [
    commercialRg
  ]
  name: 'vyos-commercial-network'
  scope: resourceGroup(commercialSubscriptionId, commercialResourceGroupName)
  params: {
    vnetName: commercialVnetName
    addressSpace: commercialAddressSpace
    workloadSubnetPrefix: commercialWorkloadSubnetPrefix
    enableTransitRouting: enableForcedInternetEgress
    transitNextHopIp: hubNvaPrivateIp
    transitPrefixes: commercialTransitPrefixes
    tags: tags
  }
}

module governmentNetwork '../../shared/modules/network/spoke-vnet.bicep' = {
  dependsOn: [
    governmentRg
  ]
  name: 'vyos-government-network'
  scope: resourceGroup(governmentSubscriptionId, governmentResourceGroupName)
  params: {
    vnetName: governmentVnetName
    addressSpace: governmentAddressSpace
    workloadSubnetPrefix: governmentWorkloadSubnetPrefix
    enableTransitRouting: enableForcedInternetEgress
    transitNextHopIp: hubNvaPrivateIp
    transitPrefixes: governmentTransitPrefixes
    tags: tags
  }
}

module vyos '../../shared/modules/nva/vyos-nva.bicep' = {
  dependsOn: [
    hubRg
  ]
  name: 'vyos-hub-appliance'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    vmName: nvaVmName
    subnetId: hubNetwork.outputs.nvaSubnetId
    privateIpAddress: hubNvaPrivateIp
    adminUsername: nvaAdminUsername
    adminPassword: nvaAdminPassword
    vmSize: nvaVmSize
    adminSourcePrefix: adminSourcePrefix
    tags: tags
  }
}

module hubToCommercial '../../shared/modules/network/peering.bicep' = {
  dependsOn: [
    hubRg
    hubNetwork
    commercialNetwork
  ]
  name: 'vyos-hub-to-commercial'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    localVnetName: hubVnetName
    peeringName: 'hub-to-commercial'
    remoteVnetId: commercialNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module commercialToHub '../../shared/modules/network/peering.bicep' = {
  dependsOn: [
    commercialRg
    commercialNetwork
    hubNetwork
  ]
  name: 'vyos-commercial-to-hub'
  scope: resourceGroup(commercialSubscriptionId, commercialResourceGroupName)
  params: {
    localVnetName: commercialVnetName
    peeringName: 'commercial-to-hub'
    remoteVnetId: hubNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module hubToGovernment '../../shared/modules/network/peering.bicep' = {
  dependsOn: [
    hubRg
    hubNetwork
    governmentNetwork
  ]
  name: 'vyos-hub-to-government'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    localVnetName: hubVnetName
    peeringName: 'hub-to-government'
    remoteVnetId: governmentNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module governmentToHub '../../shared/modules/network/peering.bicep' = {
  dependsOn: [
    governmentRg
    governmentNetwork
    hubNetwork
  ]
  name: 'vyos-government-to-hub'
  scope: resourceGroup(governmentSubscriptionId, governmentResourceGroupName)
  params: {
    localVnetName: governmentVnetName
    peeringName: 'government-to-hub'
    remoteVnetId: hubNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module commercialVm '../../shared/modules/compute/hardened-test-vm.bicep' = if (deployCommercialTestVm) {
  dependsOn: [
    commercialRg
  ]
  name: 'vyos-commercial-test-vm'
  scope: resourceGroup(commercialSubscriptionId, commercialResourceGroupName)
  params: {
    vmName: commercialTestVmName
    subnetId: commercialNetwork.outputs.workloadSubnetId
    adminUsername: testVmAdminUsername
    sshPublicKey: testVmSshPublicKey
    vmSize: commercialTestVmSize
    deployPublicIp: deployTestVmPublicIp
    adminSourcePrefix: adminSourcePrefix
    tags: union(tags, { lane: 'commercial', role: 'test-vm' })
  }
}

module governmentVm '../../shared/modules/compute/hardened-test-vm.bicep' = if (deployGovernmentTestVm) {
  dependsOn: [
    governmentRg
  ]
  name: 'vyos-government-test-vm'
  scope: resourceGroup(governmentSubscriptionId, governmentResourceGroupName)
  params: {
    vmName: governmentTestVmName
    subnetId: governmentNetwork.outputs.workloadSubnetId
    adminUsername: testVmAdminUsername
    sshPublicKey: testVmSshPublicKey
    vmSize: governmentTestVmSize
    deployPublicIp: deployTestVmPublicIp
    adminSourcePrefix: adminSourcePrefix
    tags: union(tags, { lane: 'government', role: 'test-vm' })
  }
}

output hubVnetId string = hubNetwork.outputs.vnetId
output commercialVnetId string = commercialNetwork.outputs.vnetId
output governmentVnetId string = governmentNetwork.outputs.vnetId
output nvaPrivateIp string = vyos.outputs.privateIp
output nvaPublicIp string = vyos.outputs.publicIp
