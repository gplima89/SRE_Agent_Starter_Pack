targetScope = 'subscription'

@description('Dedicated agent resource group to create. Confirm this name is unused before deployment; ARM can update an existing group with the same name.')
@minLength(2)
@maxLength(63)
param agentResourceGroupName string

@description('Agent name validated by the setup generator.')
@minLength(2)
@maxLength(32)
param agentName string

@description('Customer-confirmed agent region; also used for the new resource group metadata location.')
@minLength(1)
param location string

@description('One existing workload group in the target subscription, separate from the agent group.')
param workloadResourceGroupName string = ''

@description('Optional Reader and Log Analytics Reader grants on the workload group. No subscription-level role grants.')
param assignWorkloadReaderRoles bool = false

@description('Existing Application Insights resource group in the target subscription; not created by this wrapper.')
@minLength(1)
param applicationInsightsResourceGroupName string

@description('Existing Application Insights component for agent telemetry.')
@minLength(1)
param applicationInsightsName string

@description('Provider identifier confirmed available in the target subscription and region.')
@minLength(1)
param modelProvider string

@description('Model identifier confirmed available for the selected provider.')
@minLength(1)
param modelName string

@description('Non-sensitive ownership and cost labels for the new group, agent and identity.')
param tags object

resource agentResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: agentResourceGroupName
  location: location
  tags: tags
}

module foundation './main.bicep' = {
  name: 'sre-foundation'
  scope: agentResourceGroup
  params: {
    agentName: agentName
    location: location
    workloadResourceGroupName: workloadResourceGroupName
    assignWorkloadReaderRoles: assignWorkloadReaderRoles
    applicationInsightsResourceGroupName: applicationInsightsResourceGroupName
    applicationInsightsName: applicationInsightsName
    modelProvider: modelProvider
    modelName: modelName
    tags: tags
  }
}

output agentResourceGroupId string = agentResourceGroup.id
output agentId string = foundation.outputs.agentId