using '../main.bicep'

// Development settings. Edit quoted values below; true/false are not quoted.
// readEnvironmentVariable reads the shell running Bicep, not config/dev.json or .env.
// PowerShell example: $env:SRE_APPINSIGHTS_NAME = 'appi-contoso-orders-sre-dev'
// Required environment variables must be set before parameter compilation.
// Subscription, tenant and the existing agent resource group are selected outside this file.
// Examples are fictional; resource names must identify your actual resources. Never put secrets in tags.

// Agent resource name: 2-32 characters, starts with a letter, ends with a letter or number.
// Use letters, numbers and hyphens only. Example: 'contoso-orders-sre-dev'.
// The managed identity is named <agentName>-identity; changing this name can create new resources.
param agentName = 'fabrikam-catalog-sre-dev'

// Azure region identifier, not a display name. Example: $env:SRE_AGENT_LOCATION = 'eastus2'
// This is a syntax example, not a supported-region guarantee. Confirm SRE Agent/model availability.
param location = readEnvironmentVariable('SRE_AGENT_LOCATION')

// Optional existing workload resource group in the deployment subscription, not the agent group.
// Example: $env:SRE_WORKLOAD_RESOURCE_GROUP = 'rg-contoso-orders-dev'
// Unset or empty means no workload scope; only one group is supported by this template.
param workloadResourceGroupName = readEnvironmentVariable('SRE_WORKLOAD_RESOURCE_GROUP', '')

// Accepts false (default: no new workload grants) or true (explicit reader-role opt-in).
// true grants Reader and Log Analytics Reader to both agent identities on the workload group.
// Requires a nonempty workload group and deployment permission to assign roles.
// Does not grant agent user access or write roles; false does not remove existing grants.
param assignWorkloadReaderRoles = false

// Existing Application Insights resource group in the deployment subscription.
// Example: $env:SRE_APPINSIGHTS_RESOURCE_GROUP = 'rg-contoso-observability-dev'
// The component is reused, not created or owned by this deployment.
param applicationInsightsResourceGroupName = readEnvironmentVariable('SRE_APPINSIGHTS_RESOURCE_GROUP')

// Name of that existing Application Insights component, not its resource ID or connection string.
// Example: $env:SRE_APPINSIGHTS_NAME = 'appi-contoso-orders-sre-dev'
// Used for agent telemetry; does not configure a workload log connector.
param applicationInsightsName = readEnvironmentVariable('SRE_APPINSIGHTS_NAME')

// Exact, nonempty provider identifier confirmed for SRE Agent in your subscription/region.
// Input example: $env:SRE_MODEL_PROVIDER = '<confirmed-provider-identifier>'
// Replace the placeholder with a supported value; no universal provider allowlist is verified here.
param modelProvider = readEnvironmentVariable('SRE_MODEL_PROVIDER')

// Exact, nonempty model identifier supported by the selected provider and region.
// Input example: $env:SRE_MODEL_NAME = '<confirmed-model-identifier>'
// Replace the placeholder with a supported value, not a display label; review data residency first.
param modelName = readEnvironmentVariable('SRE_MODEL_NAME')

// Non-sensitive labels applied to the new agent and managed identity; values are strings.
// These do not rename resources or set subscription, permissions, billing limits or retention.
// Keep matching JSON configuration labels consistent manually; there is no automatic sync.
param tags = {
  // Environment label. Examples across this kit: 'dev', 'test', 'prod'; use 'dev' here.
  environment: 'dev'
  // Tool/provenance label. Example: 'azure-sre-agent-starter'; not proof of deletion ownership.
  managedBy: 'azure-sre-agent-starter'
  // Workload/project label. Example: 'orders'; does not automatically change agentName.
  workload: 'catalog'
  // Approved cost allocation code. Example: 'CC-1234'; does not enforce a spending cap.
  costCenter: 'example-lab'
  // Accountable business team. Example: 'commerce-team'; label only, not an access grant.
  businessOwner: 'example-business-team'
  // Responsible operations team. Example: 'platform-operations'; label only.
  technicalOwner: 'example-platform-team'
  // Approved classification label. Example: 'internal'; does not enforce data protection.
  dataClassification: 'internal'
}