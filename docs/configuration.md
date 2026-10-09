# Starter Configuration

These JSON documents are local intent, not product configuration. The kit does
not apply them to Azure yet. The schema deliberately accepts only Stage 0/1,
Review, no actions, no incident platform, no notification writes, and disabled
automation. A future version must add reviewed adapters before relaxing them.

## Configure and Validate

1. Choose config/dev.json, config/test.json, or config/prod.json. Change fictional
   organization, workload, owner, cost center, and classification labels.
2. Keep an independent agent resource group and workload resource group. Allowed
   scopes accepts at most one workload resource-group ID, never a subscription
   or management group. An explicit subscription ID must match that scope.
3. Leave unknown customer inputs empty rather than guessing. Select a region and
   model only after the current subscription creation picker and residency review
   confirm them. This foundation freezes model fields empty pending adapter work.
4. Match environment, workload, cost center, owner, and classification tags to
   their top-level values. Tags are not access controls or ownership proof.
5. Run from the root in PowerShell 7:

   ```powershell
   ./scripts/powershell/Test-Configuration.ps1 -ConfigPath ./config/dev.json
   ```

Expected: Status PASS, Stage 0, DeploymentReadiness NOT CHECKED. A passing file
does not prove Azure permissions, region availability, connectors, or approval.
No Azure permission is required; no resource or credential is created. A schema
failure stops the command without printing the configuration contents. Correct
the indicated field locally; rollback is an editor undo, not cloud deletion.

## Fields

| Field | Meaning and validation |
| --- | --- |
| schemaVersion | Kit contract version, currently 1.0. |
| organizationName, workloadName | Fictional prefixes; kit slugs 2-20 lowercase characters. |
| environment | dev, test, prod; separate settings per environment. |
| tenantId, subscriptionId | Empty during preparation or customer GUIDs; never credentials. |
| deploymentRegion | Empty or canonical-name syntax; availability NOT CHECKED. |
| resourceGroup | Agent RG name; deliberately stricter lowercase kit naming. |
| agentName | Official ARM 2-32 character naming rule; uniqueness NOT CHECKED. |
| logAnalyticsWorkspace, applicationInsightsInstance | Customer-approved names or IDs for future resolver; no automatic resource lookup. |
| githubOrganization, githubRepository | Workload repository coordinates, not a PAT or App private key. |
| azureDevOpsOrganization, azureDevOpsProject | Optional coordinates; no connection inferred. |
| incidentManagementPlatform, notificationChannel | None and empty until verified approved integrations are implemented. |
| deploymentMode | Desired backend only: bicep, powershell, bash, azd, terraform. |
| agentOperatingStage | 0 observe or 1 recommend; kit policy, not Azure API enum. |
| runMode | Review; each future task/plan must also explicitly set Review. |
| automationsEnabled | false; local intent, not an Azure applied switch. |
| allowedAzureScopes | Zero or one resource-group ID; subscription must match. |
| allowedActions | Empty; no writes, even for dev. |
| tags | Required environment, managedBy, workload, costCenter, owners, classification. |
| costCenter, businessOwner, technicalOwner | Fictional labels replaced by non-sensitive owner/team references. |
| dataClassification | public, internal, confidential, restricted: kit categories, not Azure policy. |
| retentionDays | Null until approved; kit range 1-730 is not a promise of service-supported retention. Adapter must validate the selected service/table retention range. |
| modelProvider, modelName | Empty; do not substitute schema examples for available provider/model choices. |

`-RequireDeploymentInputs` additionally checks that cloud coordinates, one scope,
repository, telemetry, and retention are provided. It is **not** a deployment
preflight. Do not bypass the unresolved contract/security gates when it passes.

Unknown properties are rejected, including credential fields. This is not a
secret scanner: credentials pasted into free text remain unsafe. Never put
tokens, connection strings, personal contacts, or private keys in any field.
Avoid sensitive data in resource tags because many Azure readers can see them.
Configuration JSON/YAML must not be used as an executable shell command.

Sources: [ARM reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents),
[run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes),
[creation](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up).