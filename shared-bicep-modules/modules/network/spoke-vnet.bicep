targetScope = 'resourceGroup'

@description('Spoke VNet name.')
param vnetName string

@description('Spoke VNet address spaces.')
param addressSpace array

@description('Workload subnet name.')
param workloadSubnetName string = 'WorkloadSubnet'

@description('Workload subnet prefix.')
param workloadSubnetPrefix string

@description('Whether to attach a default route to the NVA.')
param enableTransitRouting bool = false

@description('Next hop IP address of the NVA when transit routes are enabled.')
param transitNextHopIp string = ''

@description('CIDR prefixes to steer to the NVA using VirtualAppliance routes.')
param transitPrefixes array = []

@description('Route table name.')
param routeTableName string = '${vnetName}-rt'

@description('Tags to apply.')
param tags object = {}

resource rt 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: resourceGroup().location
  tags: tags
}

resource spokeRoutes 'Microsoft.Network/routeTables/routes@2024-05-01' = [for (prefix, i) in transitPrefixes: if (!empty(transitNextHopIp)) {
  parent: rt
  name: 'transit-${i + 1}'
  properties: {
    addressPrefix: string(prefix)
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: transitNextHopIp
  }
}]

resource defaultRoute 'Microsoft.Network/routeTables/routes@2024-05-01' = if (enableTransitRouting && !empty(transitNextHopIp)) {
  parent: rt
  name: 'default-to-nva'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: transitNextHopIp
  }
}

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
        name: workloadSubnetName
        properties: {
          addressPrefix: workloadSubnetPrefix
          routeTable: {
            id: rt.id
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output workloadSubnetId string = '${vnet.id}/subnets/${workloadSubnetName}'
output routeTableId string = rt.id
