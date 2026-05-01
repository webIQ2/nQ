targetScope = 'resourceGroup'

@description('vSRX VM name.')
param vmName string = 'vsrx-hub'

@description('Subnet ID for the vSRX NIC.')
param subnetId string

@description('Private IP address to assign to vSRX.')
param privateIpAddress string

@description('Admin username for the vSRX appliance.')
param adminUsername string = 'azureuser'

@secure()
@description('Admin password for the vSRX appliance.')
param adminPassword string

@description('VM size for vSRX.')
param vmSize string = 'Standard_D3_v2'

@description('Source prefix allowed to manage the vSRX appliance.')
param adminSourcePrefix string

@description('Image publisher.')
param imagePublisher string = 'Juniper Networks'

@description('Image offer.')
param imageOffer string = 'vSRX Virtual Firewall-next-generation-firewall'

@description('Image SKU.')
param imageSku string = 'vSRX Virtual Firewall-byol-azure-image'

@description('Image version.')
param imageVersion string = 'latest'

@description('Enable accelerated networking when supported.')
param enableAcceleratedNetworking bool = false

@description('Tags to apply.')
param tags object = {}

var nicName = '${vmName}-nic'
var publicIpName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: resourceGroup().location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: resourceGroup().location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-From-Admin'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminSourcePrefix
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTPS-From-Admin'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: adminSourcePrefix
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: resourceGroup().location
  tags: tags
  properties: {
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: true
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIpAddress
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: resourceGroup().location
  tags: tags
  plan: {
    publisher: imagePublisher
    product: imageOffer
    name: imageSku
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIp string = publicIp.properties.ipAddress
output vmId string = vm.id
