targetScope = 'tenant'

param managementGroupId string
param subscriptionId string

resource association 'Microsoft.Management/managementGroups/subscriptions@2020-05-01' = {
  name: '${managementGroupId}/${subscriptionId}'
}
