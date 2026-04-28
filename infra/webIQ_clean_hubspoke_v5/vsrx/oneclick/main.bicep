targetScope = 'tenant'

@description('Deployment location metadata for tenant-scope deployment records.')
param deploymentLocation string = 'eastus2'

@description('Hub subscription ID (defaults to webIQ Infrastructure).')
param hubSubscriptionId string = '7426560d-ace3-4e95-9df4-69985fb9d8cc'

@description('Commercial spoke subscription ID (defaults to netIQ).')
param commercialSubscriptionId string = 'ff60f646-9751-4074-9f58-9fc310105c4c'

@description('Government spoke subscription ID (defaults to Gi).')
param governmentSubscriptionId string = '1011dd77-657c-4c57-931b-0b77b92e7378'

param hubResourceGroupName string = 'rg-webiq-vsrx-hub'
param commercialResourceGroupName string = 'rg-netiq-vsrx-commercial'
param governmentResourceGroupName string = 'rg-gi-vsrx-government'

param hubLocation string = 'eastus2'
param commercialLocation string = 'eastus2'
param governmentLocation string = 'eastus2'

param hubVnetName string = 'vnet-webiq-vsrx-hub'
param commercialVnetName string = 'vnet-netiq-commercial'
param governmentVnetName string = 'vnet-gi-government'

param hubAddressSpace array = [ '10.60.0.0/16' ]
param commercialAddressSpace array = [ '10.61.0.0/16' ]
param governmentAddressSpace array = [ '10.62.0.0/16' ]

param hubNvaSubnetPrefix string = '10.60.1.0/24'
param hubNvaPrivateIp string = '10.60.1.4'
param commercialWorkloadSubnetPrefix string = '10.61.1.0/24'
param governmentWorkloadSubnetPrefix string = '10.62.1.0/24'

param nvaVmName string = 'vsrx-hub'
param nvaAdminUsername string = 'azureuser'
@secure()
param nvaAdminPassword string
param nvaVmSize string = 'Standard_D3_v2'
param adminSourcePrefix string

param deployCommercialTestVm bool = true
param deployGovernmentTestVm bool = true
param testVmAdminUsername string = 'azureuser'
param testVmSshPublicKey string
param commercialTestVmName string = 'vm-commercial-test'
param governmentTestVmName string = 'vm-government-test'
param commercialTestVmSize string = 'Standard_B1ms'
param governmentTestVmSize string = 'Standard_B1ms'
param deployTestVmPublicIp bool = false

@description('Set to true only after the NVA is configured to forward traffic.')
param enableTransitRouting bool = false

param tags object = {
  workload: 'hub-spoke'
  nvaVendor: 'vSRX'
  owner: 'webIQ'
}

module hubRg '../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vsrx-hub-rg'
  scope: subscription(hubSubscriptionId)
  params: {
    resourceGroupName: hubResourceGroupName
    location: hubLocation
    tags: tags
  }
}

module commercialRg '../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vsrx-commercial-rg'
  scope: subscription(commercialSubscriptionId)
  params: {
    resourceGroupName: commercialResourceGroupName
    location: commercialLocation
    tags: tags
  }
}

module governmentRg '../../shared/modules/foundation/resource-group.bicep' = {
  name: 'vsrx-government-rg'
  scope: subscription(governmentSubscriptionId)
  params: {
    resourceGroupName: governmentResourceGroupName
    location: governmentLocation
    tags: tags
  }
}

module hubNetwork '../../shared/modules/network/hub-vnet.bicep' = {
  name: 'vsrx-hub-network'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  dependsOn: [ hubRg ]
  params: {
    vnetName: hubVnetName
    addressSpace: hubAddressSpace
    nvaSubnetPrefix: hubNvaSubnetPrefix
    tags: tags
  }
}

module commercialNetwork '../../shared/modules/network/spoke-vnet.bicep' = {
  name: 'vsrx-commercial-network'
  scope: resourceGroup(commercialSubscriptionId, commercialResourceGroupName)
  dependsOn: [ commercialRg ]
  params: {
    vnetName: commercialVnetName
    addressSpace: commercialAddressSpace
    workloadSubnetPrefix: commercialWorkloadSubnetPrefix
    enableTransitRouting: enableTransitRouting
    transitNextHopIp: hubNvaPrivateIp
    tags: tags
  }
}

module governmentNetwork '../../shared/modules/network/spoke-vnet.bicep' = {
  name: 'vsrx-government-network'
  scope: resourceGroup(governmentSubscriptionId, governmentResourceGroupName)
  dependsOn: [ governmentRg ]
  params: {
    vnetName: governmentVnetName
    addressSpace: governmentAddressSpace
    workloadSubnetPrefix: governmentWorkloadSubnetPrefix
    enableTransitRouting: enableTransitRouting
    transitNextHopIp: hubNvaPrivateIp
    tags: tags
  }
}

module vsrx '../../shared/modules/nva/vsrx-nva.bicep' = {
  name: 'vsrx-hub-appliance'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  dependsOn: [ hubNetwork ]
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
  name: 'vyos-hub-to-commercial'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  dependsOn: [ hubNetwork, commercialNetwork ]
  params: {
    localVnetName: hubVnetName
    peeringName: 'hub-to-commercial'
    remoteVnetId: commercialNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module commercialToHub '../../shared/modules/network/peering.bicep' = {
  name: 'vyos-commercial-to-hub'
  scope: resourceGroup(commercialSubscriptionId, commercialResourceGroupName)
  dependsOn: [ hubNetwork, commercialNetwork ]
  params: {
    localVnetName: commercialVnetName
    peeringName: 'commercial-to-hub'
    remoteVnetId: hubNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module hubToGovernment '../../shared/modules/network/peering.bicep' = {
  name: 'vyos-hub-to-government'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  dependsOn: [ hubNetwork, governmentNetwork ]
  params: {
    localVnetName: hubVnetName
    peeringName: 'hub-to-government'
    remoteVnetId: governmentNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module governmentToHub '../../shared/modules/network/peering.bicep' = {
  name: 'vyos-government-to-hub'
  scope: resourceGroup(governmentSubscriptionId, governmentResourceGroupName)
  dependsOn: [ hubNetwork, governmentNetwork ]
  params: {
    localVnetName: governmentVnetName
    peeringName: 'government-to-hub'
    remoteVnetId: hubNetwork.outputs.vnetId
    allowForwardedTraffic: true
  }
}

module commercialVm '../../shared/modules/compute/hardened-test-vm.bicep' = if (deployCommercialTestVm) {
  name: 'vsrx-commercial-test-vm'
  scope: resourceGroup(commercialSubscriptionId, commercialResourceGroupName)
  dependsOn: [ commercialNetwork ]
  params: {
    vmName: commercialTestVmName
    subnetId: commercialNetwork.outputs.workloadSubnetId
    adminUsername: testVmAdminUsername
    sshPublicKey: testVmSshPublicKey
    vmSize: commercialTestVmSize
    deployPublicIp: deployTestVmPublicIp
    adminSourcePrefix: adminSourcePrefix
    tags: union(tags, { lane: 'commercial' })
  }
}

module governmentVm '../../shared/modules/compute/hardened-test-vm.bicep' = if (deployGovernmentTestVm) {
  name: 'vsrx-government-test-vm'
  scope: resourceGroup(governmentSubscriptionId, governmentResourceGroupName)
  dependsOn: [ governmentNetwork ]
  params: {
    vmName: governmentTestVmName
    subnetId: governmentNetwork.outputs.workloadSubnetId
    adminUsername: testVmAdminUsername
    sshPublicKey: testVmSshPublicKey
    vmSize: governmentTestVmSize
    deployPublicIp: deployTestVmPublicIp
    adminSourcePrefix: adminSourcePrefix
    tags: union(tags, { lane: 'government' })
  }
}

output hubVnetId string = hubNetwork.outputs.vnetId
output commercialVnetId string = commercialNetwork.outputs.vnetId
output governmentVnetId string = governmentNetwork.outputs.vnetId
output nvaPrivateIp string = vsrx.outputs.privateIp
output nvaPublicIp string = vsrx.outputs.publicIp
