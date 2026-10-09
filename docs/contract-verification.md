# Contract Verification and Phase 3 Baseline

Reviewed 2026-10-09. Local compilation is verified; provisioning and runtime
controls are NOT CHECKED. This baseline is not the completed starter kit.

## Source Findings

Directly inspected official files at commit
`25a42306d298c4d28f11dd11ef9bb93cb0393be8`:

- [agent-core.bicep](https://github.com/microsoft/sre-agent/blob/25a42306d298c4d28f11dd11ef9bb93cb0393be8/sreagent-templates/bicep/agent-core.bicep)
  uses `2025-05-01-preview`, Low/Review, SAMI/UAMI, sensitive telemetry references,
  preview fields, and Administrator assignments for deployer and UAMI.
- [role-assignments-target.bicep](https://github.com/microsoft/sre-agent/blob/25a42306d298c4d28f11dd11ef9bb93cb0393be8/sreagent-templates/bicep/role-assignments-target.bicep)
  uses Reader and Log Analytics Reader, plus Contributor only for High access.
  It contains no Monitoring Contributor assignment. This establishes template
  behavior, not proof that every investigation works with these roles.
- [main.bicep](https://github.com/microsoft/sre-agent/blob/25a42306d298c4d28f11dd11ef9bb93cb0393be8/sreagent-templates/bicep/main.bicep)
  is subscription-scoped, defaults Preview upgrades, and carries optional
  connectors, schedules, hooks, egress and preview-specific properties.
- [2026-01-01 ARM contract](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents)
  documents Low/High, Review/ReadOnly/Autonomous, identities, telemetry, model,
  knowledge graph, and Stable/Preview. It is the selected contract here.

Do not equate upstream Automatic with the newer Autonomous enum or transplant
preview properties. No version compatibility shim or warning suppression is used.
No API adapter for hooks or connectors has been certified.

## Decisions and Remaining Gates

| Gate | Outcome |
| --- | --- |
| Resource version | Resolved for core resource: explicitly 2026-01-01; compiler accepts it. Provider support in customer subscription remains NOT CHECKED. |
| Scope and grants | Template grants only optional RG Reader/Log Analytics Reader to SAMI/UAMI. No subscription grants or Administrator grants. Effective inherited roles still require live review. |
| Model and region | Mandatory explicit inputs, no defaults. Customer verifies picker availability and residency. |
| Approval | Fixed Review/Low, no tasks/incidents/hooks. Not a complete no-write guarantee: OBO and policy/hook precedence require runtime negative tests. |
| Telemetry | Existing App Insights referenced inside template, sensitive value passed into secure module parameter, never output. This is agent telemetry, not a workload connector. |
| New telemetry modules | Deferred: discovered AVMs expose workspace shared keys or telemetry credentials as nested outputs. No insecure module-output propagation introduced. |
| Data-plane configuration | Still blocked: verify each versioned schema/auth flow separately and test negative approval scenarios. |
| Deployment automation | Still pending preflight, inventory, safe confirmation, live validation, cleanup, parity scripts, and CI environment protection. |

Source review also found the upstream SAMI target-role loop is outside its
skipRoleAssignments guard. Our two identity-role paths both obey the same
explicit opt-in condition, tested against compiled ARM.

## Implemented IaC

[Main template](../infra/bicep/main.bicep) targets an existing dedicated agent
resource group. It creates a dedicated UAMI and an SRE Agent, references an
existing App Insights component in the same subscription, and optionally grants
the two reader roles on one workload RG. Existing telemetry is shared/customer
owned and must never be included in a future solution removal inventory.

[Agent module](../infra/bicep/modules/agent.bicep) has no privileged/autonomous
toggle. [Workload role module](../infra/bicep/modules/workload-readers.bicep)
allows no caller-supplied role name. Identity AVM 0.6.0 and RG role AVM 0.1.0
are pinned; AVM usage telemetry is disabled. Role assignment GUIDs are
deterministic. Deterministic names support repeatability, but idempotent Azure
deployment and role-conflict behavior are not yet tested.

## Local Validation

1. Install Azure CLI and Bicep using [official installation guidance](01-prerequisites.md).
2. From repository root, in PowerShell 7:

   ```powershell
   ./tests/unit/Test-Infrastructure.Tests.ps1
   ./tests/unit/Test-Repository.Tests.ps1
   ./tests/unit/Test-Configuration.Tests.ps1
   ./scripts/powershell/Test-Repository.ps1
   ```

3. Expected: 41 infrastructure checks, five repository regressions, 21
   configuration checks, then repository PASS. Initial AVM restore needs network
   access to the public Bicep registry. No Azure login or role is required for
   compilation. No cloud resources change and no service cost is incurred.
4. The infrastructure test temporarily sets process environment inputs to
   synthetic values and restores them in finally. Those values test compilation,
   not model eligibility or deployment readiness.

The dev/test/prod bicepparam examples require SRE_AGENT_LOCATION,
SRE_APPINSIGHTS_RESOURCE_GROUP, SRE_APPINSIGHTS_NAME, SRE_MODEL_PROVIDER,
SRE_MODEL_NAME, and optional SRE_WORKLOAD_RESOURCE_GROUP. They are separate from
the kit JSON intent; no automatic translation or deployment script exists yet.
Missing required environment variables fail parameter compilation intentionally.

## Before Any Cloud Deployment

- Confirm tenant/subscription, provider version, region/model, dedicated RG,
  scope separation, naming, tags and telemetry access with the customer.
- Require resource write permission on the agent RG; role assignment permission
  on the workload RG only if reader grants are opted into. Separate an access
  administrator from the deployment identity where possible. Never demand
  subscription Owner for this resource-group baseline.
- Verify actual role definitions and inherited assignments. Review mode is not
  an RBAC substitute. Agent users must receive separately reviewed product roles;
  this template grants none, so portal use is not enabled automatically.
- Capture baseline inventory; review what-if; prepare evidence retention and
  an inventory-backed cleanup procedure before creating resources.
- No direct cloud command is included here until those lifecycle gates exist.
  Local rollback is an editor undo of kit changes, never deletion of reused
  telemetry. Do not treat a name prefix/tag as deletion ownership proof.
- Agent fixed billing continues while provisioned, even when stopped. Confirm
  [costs](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing) and
  [inference residency](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy)
  before a lab. Production deployment remains unapproved.