targetScope = 'resourceGroup'

metadata description = 'SRE Agent lab foundation. Review/Low access only. Creates monitoring by default or reuses existing Application Insights. Runtime readiness, model availability and cleanup are not verified. See docs/portal-deployment.md before deployment.'

@description('Agent name. Example: contoso-orders-sre-dev. Use 2-32 letters, numbers or hyphens; start with a letter and end with a letter or number. Changing a deployed name can create a new agent.')
@minLength(2)
@maxLength(32)
param agentName string

@description('Confirmed SRE Agent region identifier, not a display name. eastus2 is a syntax example, not an availability guarantee. Confirm model availability and data residency first. This may differ from the resource group metadata region.')
@minLength(1)
param location string

@description('Environment label. Start with dev for an approved disposable lab. Choosing prod does not establish production readiness.')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Application/workload label for tags. Example: orders. Does not automatically rename resources or grant workload access.')
@minLength(2)
@maxLength(20)
param workloadName string

@description('Approved cost allocation label. Example: CC-1234. Not a spending cap; provisioned agent charges may continue while stopped.')
@minLength(1)
@maxLength(128)
param costCenter string

@description('Non-sensitive accountable business team label. Example: commerce-team. Do not enter personal contact details or credentials. Does not grant access.')
@minLength(1)
@maxLength(128)
param businessOwner string

@description('Non-sensitive responsible operations team label. Example: platform-operations. Does not grant access.')
@minLength(1)
@maxLength(128)
param technicalOwner string

@description('Organization-approved classification tag. This label does not enforce data protection.')
@allowed(['public', 'internal', 'confidential', 'restricted'])
param dataClassification string = 'internal'

@description('Create new creates a billable Log Analytics workspace and Application Insights in the agent group. Use existing leaves monitoring unchanged and requires an existing component name; an empty component resource group uses the agent group. Review costs, network policy and cleanup ownership first.')
@allowed(['Create new', 'Use existing'])
param monitoringMode string = 'Create new'

@description('Use existing only: Application Insights resource group in the selected subscription. Example: rg-contoso-observability. Leave empty to use the SRE agent resource group. Ignored in Create new mode.')
param applicationInsightsResourceGroupName string = ''

@description('Use existing only: Application Insights component name, not an ID or connection string. Required in reuse mode; ignored in Create new mode. New component is named <agentName>-appi.')
param applicationInsightsName string = ''

@description('Provider options may include Anthropic and Azure OpenAI, depending on your subscription and region. These are display names, not verified ARM input values. Enter the exact provider identifier confirmed for your deployment; do not guess or use a placeholder.')
@minLength(1)
@maxLength(128)
param modelProvider string

@description('Documented model-name examples: gpt-5, claude-opus-4-5, claude-sonnet-4-5. These are examples, not a supported-value list; none is guaranteed in every region. Confirm the exact provider/model combination for your subscription and region before deploying. No model is selected automatically.')
@minLength(1)
@maxLength(128)
param modelName string

@description('One existing workload resource group in this subscription. Example: rg-contoso-orders-dev. Leave empty to use the SRE agent resource group. Reader roles are assigned only when Assign Workload Reader Roles is true.')
param workloadResourceGroupName string = ''

@description('Keep false initially. true grants Reader and Log Analytics Reader to both agent identities on the named workload group. Requires role-assignment permission. Does not grant agent-user roles or write roles. false does not remove existing grants.')
param assignWorkloadReaderRoles bool = false

@description('Microsoft Entra object ID of the user or group receiving SRE Agent Administrator on this agent only. Defaults to the deployment initiator for interactive Portal deployments. Automated deployments must supply a human user or group object ID, not the pipeline identity. Requires role-assignment write permission even when workload reader roles are false.')
@minLength(36)
@maxLength(36)
param agentAdministratorPrincipalId string = deployer().objectId

@description('Type of the administrator object ID: User for interactive deployment or an explicit human user; Group for an explicit Entra group. Service principals and managed identities are not supported for this bootstrap assignment.')
@allowed(['User', 'Group'])
param agentAdministratorPrincipalType string = 'User'

var createMonitoring = monitoringMode == 'Create new'
var resolvedApplicationInsightsResourceGroupName = empty(applicationInsightsResourceGroupName) ? resourceGroup().name : applicationInsightsResourceGroupName
var resolvedWorkloadResourceGroupName = empty(workloadResourceGroupName) ? resourceGroup().name : workloadResourceGroupName
var resourceTags = {
  environment: environment
  managedBy: 'azure-sre-agent-starter'
  workload: workloadName
  costCenter: costCenter
  businessOwner: businessOwner
  technicalOwner: technicalOwner
  dataClassification: dataClassification
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = if (createMonitoring) {
  name: '${agentName}-logs'
  location: location
  tags: resourceTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (createMonitoring) {
  name: '${agentName}-appi'
  location: location
  kind: 'web'
  tags: resourceTags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    IngestionMode: 'LogAnalytics'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    DisableIpMasking: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module foundation '../bicep/main.bicep' = {
  name: 'sre-foundation'
  params: {
    agentName: agentName
    location: location
    workloadResourceGroupName: resolvedWorkloadResourceGroupName
    assignWorkloadReaderRoles: assignWorkloadReaderRoles
    applicationInsightsResourceGroupName: createMonitoring ? resourceGroup().name : resolvedApplicationInsightsResourceGroupName
    applicationInsightsName: createMonitoring ? applicationInsights.name : applicationInsightsName
    modelProvider: modelProvider
    modelName: modelName
    tags: resourceTags
  }
  dependsOn: [applicationInsights]
}

resource agent 'Microsoft.App/agents@2026-01-01' existing = {
  name: agentName
}

var agentAdministratorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e79298df-d852-4c6d-84f9-5d13249d1e55')

resource agentAdministrator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(agent.id, agentAdministratorPrincipalId, agentAdministratorRoleId)
  scope: agent
  properties: {
    roleDefinitionId: agentAdministratorRoleId
    principalId: agentAdministratorPrincipalId
    principalType: agentAdministratorPrincipalType
  }
  dependsOn: [foundation]
}

output agentId string = foundation.outputs.agentId
output managedIdentityId string = foundation.outputs.managedIdentityId
output systemAssignedPrincipalId string = foundation.outputs.systemAssignedPrincipalId
output applicationInsightsId string = foundation.outputs.reusedApplicationInsightsId