targetScope = 'resourceGroup'

@description('Local VNet name inside the current resource group.')
param localVnetName string

@description('Peering resource name.')
param peeringName string

@description('Remote VNet resource ID.')
param remoteVnetId string

@description('Allow forwarded traffic across the peering.')
param allowForwardedTraffic bool = true

@description('Allow standard VNet access across the peering.')
param allowVirtualNetworkAccess bool = true

@description('Whether this side advertises gateway transit.')
param allowGatewayTransit bool = false

@description('Whether this side uses the remote gateway.')
param useRemoteGateways bool = false

resource localVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: localVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: localVnet
  name: peeringName
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowForwardedTraffic: allowForwardedTraffic
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

output peeringId string = peering.id
