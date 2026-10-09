targetScope = 'resourceGroup'

@description('Agent name validated by the starter checker and Azure naming rules.')
@minLength(2)
@maxLength(32)
param agentName string

@description('Customer-confirmed agent region; no automatic region selection.')
@minLength(1)
param location string

@description('One existing workload RG in the active subscription, separate from this deployment RG. Leave empty for no workload resource access.')
param workloadResourceGroupName string = ''

@description('Explicit opt-in to Reader and Log Analytics Reader for SAMI/UAMI on the single workload RG. Does not grant any agent user role.')
param assignWorkloadReaderRoles bool = false

@description('Existing Application Insights resource group in this subscription. Reused telemetry is never owned by this deployment.')
@minLength(1)
param applicationInsightsResourceGroupName string

@description('Existing Application Insights component name for agent telemetry. This does not configure a workload log connector.')
@minLength(1)
param applicationInsightsName string

@description('Provider confirmed available for the customer subscription and region after data residency review.')
@minLength(1)
param modelProvider string

@description('Model confirmed available for the selected provider. Do not infer it from ARM examples.')
@minLength(1)
param modelName string

@description('Non-sensitive tags approved by workload owners.')
param tags object

module identity 'br/public:avm/res/managed-identity/user-assigned-identity:0.6.0' = {
  name: 'sre-identity'
  params: {
    name: '${agentName}-identity'
    location: location
    tags: tags
    enableTelemetry: false
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
  scope: resourceGroup(applicationInsightsResourceGroupName)
}

module agent './modules/agent.bicep' = {
  name: 'sre-agent'
  params: {
    agentName: agentName
    location: location
    managedIdentityId: identity.outputs.resourceId
    workloadResourceGroupIds: empty(workloadResourceGroupName) ? [] : [subscriptionResourceId('Microsoft.Resources/resourceGroups', workloadResourceGroupName)]
    applicationInsightsAppId: applicationInsights.properties.AppId
    applicationInsightsConnectionString: applicationInsights.properties.ConnectionString
    modelProvider: modelProvider
    modelName: modelName
    tags: tags
  }
}

module userIdentityReaders './modules/workload-readers.bicep' = if (assignWorkloadReaderRoles && !empty(workloadResourceGroupName)) {
  name: 'sre-uami-readers'
  scope: resourceGroup(workloadResourceGroupName)
  params: {
    principalId: identity.outputs.principalId
  }
}

module systemIdentityReaders './modules/workload-readers.bicep' = if (assignWorkloadReaderRoles && !empty(workloadResourceGroupName)) {
  name: 'sre-sami-readers'
  scope: resourceGroup(workloadResourceGroupName)
  params: {
    principalId: agent.outputs.systemAssignedPrincipalId
  }
}

output agentId string = agent.outputs.agentId
output managedIdentityId string = identity.outputs.resourceId
output managedIdentityPrincipalId string = identity.outputs.principalId
output systemAssignedPrincipalId string = agent.outputs.systemAssignedPrincipalId
output reusedApplicationInsightsId string = applicationInsights.id