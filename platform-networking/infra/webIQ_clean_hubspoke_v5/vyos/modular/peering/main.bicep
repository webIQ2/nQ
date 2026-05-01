targetScope = 'tenant'

param hubSubscriptionId string = '7426560d-ace3-4e95-9df4-69985fb9d8cc'
param hubResourceGroupName string = 'rg-webiq-vyos-hub'
param hubVnetName string = 'vnet-webiq-vyos-hub'
param spokeSubscriptionId string
param spokeResourceGroupName string
param spokeVnetName string
param peeringPrefix string = 'peer'

module hubToSpoke '../../../shared/modules/network/peering.bicep' = {
  name: '${peeringPrefix}-hub-to-spoke'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    localVnetName: hubVnetName
    peeringName: '${peeringPrefix}-hub-to-spoke'
    remoteVnetId: resourceId(spokeSubscriptionId, spokeResourceGroupName, 'Microsoft.Network/virtualNetworks', spokeVnetName)
    allowForwardedTraffic: true
  }
}

module spokeToHub '../../../shared/modules/network/peering.bicep' = {
  name: '${peeringPrefix}-spoke-to-hub'
  scope: resourceGroup(spokeSubscriptionId, spokeResourceGroupName)
  params: {
    localVnetName: spokeVnetName
    peeringName: '${peeringPrefix}-spoke-to-hub'
    remoteVnetId: resourceId(hubSubscriptionId, hubResourceGroupName, 'Microsoft.Network/virtualNetworks', hubVnetName)
    allowForwardedTraffic: true
  }
}
