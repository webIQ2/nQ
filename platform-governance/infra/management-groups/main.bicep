targetScope = 'tenant'

@description('Root management group ID under the tenant root group.')
param rootManagementGroupId string = 'webIQ-Root'

@description('Display name for the platform root.')
param rootManagementGroupDisplayName string = 'webIQ Cloud Root'

@description('Target tenant ID for existing tenant root management group reference.')
param tenantRootId string = tenant().tenantId

@description('Management groups to create beneath the webIQ root.')
param childManagementGroups array = [
  {
    id: 'Platform'
    displayName: 'Platform'
  }
  {
    id: 'Lifecycle'
    displayName: 'Lifecycle'
  }
  {
    id: 'Customers'
    displayName: 'Customers'
  }
  {
    id: 'Corporate'
    displayName: 'Corporate'
  }
  {
    id: 'Decommissioned'
    displayName: 'Decommissioned'
  }
]

@description('Subscriptions to place after management groups exist.')
param subscriptionPlacements array = [
  {
    managementGroupId: 'Networking'
    subscriptionId: '7426560d-ace3-4e95-9df4-69985fb9d8cc'
  }
  {
    managementGroupId: 'Management'
    subscriptionId: '604ca1f3-dab9-4da5-ac37-e8effa89c826'
  }
  {
    managementGroupId: 'IAM'
    subscriptionId: 'ebdb6704-b8fb-4908-97e6-5bbe9cc59758'
  }
  {
    managementGroupId: 'Commercial'
    subscriptionId: 'ff60f646-9751-4074-9f58-9fc310105c4c'
  }
  {
    managementGroupId: 'Government'
    subscriptionId: '1011dd77-657c-4c57-931b-0b77b92e7378'
  }
]

resource tenantRoot 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  name: tenantRootId
}

resource webiqRoot 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: rootManagementGroupId
  scope: tenant()
  properties: {
    displayName: rootManagementGroupDisplayName
    details: {
      parent: {
        id: tenantRoot.id
      }
    }
  }
}

resource children 'Microsoft.Management/managementGroups@2023-04-01' = [for mg in childManagementGroups: {
  name: mg.id
  scope: tenant()
  properties: {
    displayName: mg.displayName
    details: {
      parent: {
        id: webiqRoot.id
      }
    }
  }
  dependsOn: [
    webiqRoot
  ]
}]

module subscriptionPlacement '../modules/subscription-placement.bicep' = [for placement in subscriptionPlacements: {
  name: 'place-${placement.subscriptionId}'
  params: {
    managementGroupId: placement.managementGroupId
    subscriptionId: placement.subscriptionId
  }
}]
