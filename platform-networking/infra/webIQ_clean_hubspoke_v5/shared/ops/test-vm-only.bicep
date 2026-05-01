targetScope = 'resourceGroup'

param vmName string
param subnetId string
param adminUsername string = 'azureuser'
param sshPublicKey string
param vmSize string = 'Standard_D2s_v3'
param deployPublicIp bool = false
param adminSourcePrefix string = '0.0.0.0/0'
param tags object = {}

module vm '../modules/compute/hardened-test-vm.bicep' = {
  name: '${vmName}-deploy'
  params: {
    vmName: vmName
    subnetId: subnetId
    adminUsername: adminUsername
    sshPublicKey: sshPublicKey
    vmSize: vmSize
    deployPublicIp: deployPublicIp
    adminSourcePrefix: adminSourcePrefix
    tags: tags
  }
}

output privateIp string = vm.outputs.privateIp
output publicIp string = vm.outputs.publicIp
output vmId string = vm.outputs.vmId
