targetScope = 'resourceGroup'

@description('Agent name: 2-32 characters, starts with a letter, ends alphanumeric. Validate with the starter configuration checker.')
@minLength(2)
@maxLength(32)
param agentName string

@description('Customer-confirmed SRE Agent region and model availability. No region is selected automatically.')
@minLength(1)
param location string

@description('Resource ID of the dedicated user-assigned managed identity for workload operations.')
@minLength(1)
param managedIdentityId string

@description('Zero or one existing workload resource-group ID; separate from the agent resource group.')
@maxLength(1)
param workloadResourceGroupIds array = []

@description('Application ID of the dedicated agent telemetry component, not the workload connector.')
@minLength(1)
param applicationInsightsAppId string

@description('Sensitive agent telemetry connection string. Obtain inside the deployment; never put it in source control or outputs.')
@secure()
param applicationInsightsConnectionString string

@description('Provider value confirmed in the target subscription and region. ARM examples do not establish availability.')
@minLength(1)
param modelProvider string

@description('Model value confirmed for the selected provider. No automatic provider or model choice.')
@minLength(1)
param modelName string

@description('Non-sensitive ownership, environment, classification and cost tags.')
param tags object

resource agent 'Microsoft.App/agents@2026-01-01' = {
  name: agentName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    actionConfiguration: {
      accessLevel: 'Low'
      identity: managedIdentityId
      mode: 'Review'
    }
    knowledgeGraphConfiguration: {
      identity: managedIdentityId
      managedResources: workloadResourceGroupIds
    }
    logConfiguration: {
      applicationInsightsConfiguration: {
        appId: applicationInsightsAppId
        connectionString: applicationInsightsConnectionString
      }
    }
    defaultModel: {
      provider: modelProvider
      name: modelName
    }
    upgradeChannel: 'Stable'
  }
}

output agentId string = agent.id
output systemAssignedPrincipalId string = agent.identity.principalId