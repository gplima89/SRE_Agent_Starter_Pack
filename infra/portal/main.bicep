targetScope = 'resourceGroup'

metadata description = 'SRE Agent lab foundation. Review/Low access only. Existing Application Insights required. Runtime readiness, model availability and cleanup are not verified. See docs/portal-deployment.md before deployment.'

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

@description('Existing Application Insights resource group in the selected subscription. Example: rg-contoso-observability. Component is reused, not created. It cannot be inside a new empty agent group.')
@minLength(1)
param applicationInsightsResourceGroupName string

@description('Existing Application Insights component name. Example: appi-contoso-sre. Enter the name, not an ID or connection string. Used for agent telemetry, not workload log connectors.')
@minLength(1)
param applicationInsightsName string

@description('Exact provider identifier confirmed in the SRE Agent creation experience for this subscription and region. No universal supported-value list is verified here; do not guess or use a placeholder.')
@minLength(1)
@maxLength(128)
param modelProvider string

@description('Exact model identifier confirmed available for the chosen provider and region. Not a display label. No model is selected automatically.')
@minLength(1)
@maxLength(128)
param modelName string

@description('Optional: one existing workload resource group in this subscription, separate from the agent group. Example: rg-contoso-orders-dev. Leave empty for no workload scope.')
param workloadResourceGroupName string = ''

@description('Keep false initially. true grants Reader and Log Analytics Reader to both agent identities on the named workload group. Requires role-assignment permission. Does not grant agent-user roles or write roles. false does not remove existing grants.')
param assignWorkloadReaderRoles bool = false

module foundation '../bicep/main.bicep' = {
  name: 'sre-foundation'
  params: {
    agentName: agentName
    location: location
    workloadResourceGroupName: workloadResourceGroupName
    assignWorkloadReaderRoles: assignWorkloadReaderRoles
    applicationInsightsResourceGroupName: applicationInsightsResourceGroupName
    applicationInsightsName: applicationInsightsName
    modelProvider: modelProvider
    modelName: modelName
    tags: {
      environment: environment
      managedBy: 'azure-sre-agent-starter'
      workload: workloadName
      costCenter: costCenter
      businessOwner: businessOwner
      technicalOwner: technicalOwner
      dataClassification: dataClassification
    }
  }
}

output agentId string = foundation.outputs.agentId
output managedIdentityId string = foundation.outputs.managedIdentityId
output systemAssignedPrincipalId string = foundation.outputs.systemAssignedPrincipalId
output reusedApplicationInsightsId string = foundation.outputs.reusedApplicationInsightsId