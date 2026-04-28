targetScope = 'resourceGroup'

@description('Test VM name.')
param vmName string

@description('Subnet ID for the test VM NIC.')
param subnetId string

@description('Admin username for the test VM.')
param adminUsername string = 'azureuser'

@description('SSH public key for the test VM.')
param sshPublicKey string

@description('VM size for the test VM.')
param vmSize string = 'Standard_D2s_v3'

@description('Whether to deploy a public IP for the test VM.')
param deployPublicIp bool = false

@description('Source prefix allowed to SSH when a public IP is deployed.')
param adminSourcePrefix string = '0.0.0.0/0'

#disable-next-line no-hardcoded-env-urls
@description('Commercial cloud probe hosts.')
param commercialProbeHosts array = [
  'management.azure.com'
  'login.microsoftonline.com'
  'portal.azure.com'
]

#disable-next-line no-hardcoded-env-urls
@description('Government cloud probe hosts.')
param governmentProbeHosts array = [
  'management.usgovcloudapi.net'
  'login.microsoftonline.us'
  'portal.azure.us'
]

@description('Tags to apply.')
param tags object = {}

var nicName = '${vmName}-nic'
var publicIpName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'
var commercialProbeList = join(commercialProbeHosts, ' ')
var governmentProbeList = join(governmentProbeHosts, ' ')
var sshRules = deployPublicIp ? [
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
] : []

var cloudInit = '''
#cloud-config
package_update: true
package_upgrade: true
packages:
  - curl
  - traceroute
  - iputils-ping
write_files:
  - path: /usr/local/bin/probe-clouds.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -u
      LOG=/var/log/cloud-probe.log
      {
        echo "=== commercial ==="
        for host in ${commercialProbeList}; do
          code=$(curl -ksS -o /dev/null -w '%{http_code}' --max-time 10 https://$host || true)
          echo "$host $code"
        done
        echo "=== government ==="
        for host in ${governmentProbeList}; do
          code=$(curl -ksS -o /dev/null -w '%{http_code}' --max-time 10 https://$host || true)
          echo "$host $code"
        done
      } | tee "$LOG"
runcmd:
  - [ bash, /usr/local/bin/probe-clouds.sh ]
'''

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (deployPublicIp) {
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
    securityRules: sshRules
  }
}

var nicIpConfig = deployPublicIp
  ? {
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: subnetId
        }
        publicIPAddress: {
          id: publicIp.id
        }
      }
    }
  : {
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: subnetId
        }
      }
    }

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: resourceGroup().location
  tags: tags
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      nicIpConfig
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: resourceGroup().location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      customData: base64(cloudInit)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        provisionVMAgent: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
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
output publicIp string = deployPublicIp ? reference(publicIp.id, '2024-05-01').ipAddress : ''
output vmId string = vm.id
