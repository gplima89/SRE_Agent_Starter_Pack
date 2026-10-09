# Phase 1: Discovery and Implementation Plan

Evidence reviewed: 2026-10-09. This is a starter-kit design, not authorization
to deploy, grant access, or incur charges in a customer subscription.

Follow-up: [Contract verification](contract-verification.md) records direct
inspection of pinned templates, a locally compiled core Bicep baseline, and
which gates remain live-validation requirements. The original findings below
are the discovery record, not a claim that no implementation has since occurred.

## Solution Summary

Create a beginner-friendly, modular kit for deploying and operating Azure SRE
Agent. Begin with one agent, one non-production workload resource group, one
code repository, and one telemetry source. Bicep is primary; Terraform uses
AzAPI only where the ARM contract supports the same operation. Use the UAMI
for workload access and connector authentication; agent infrastructure also
uses a system-assigned identity in the documented creation flow.

Stage 0 observes and Stage 1 recommends. Neither permits resource changes.
All response plans and tasks must explicitly select Review and start disabled.
This five-stage maturity model is a starter policy, not an Azure enum.
Review is only one control: permissions, connector restrictions, hooks, OBO
authorization, and tool policies must also be reviewed.

## Verified Sources

Directly retrieved sources, in priority order:

| Source | Verified decision or limitation |
| --- | --- |
| [Overview](https://learn.microsoft.com/en-us/azure/sre-agent/overview) | Investigations, skills, custom agents, hooks, MCP, and integrations are documented. |
| [Create and set up](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up) | Code/log onboarding, SAMI plus UAMI, and resource-group scope are documented. Available providers depend on subscription and region. |
| [Supported regions](https://learn.microsoft.com/en-us/azure/sre-agent/supported-regions) | The dedicated reference lists 22 regions; subscription availability must still be checked in the creation picker. |
| [Run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes) | Tasks/plans default to Autonomous; Review gates Azure infrastructure operations, not all external actions. |
| [User roles](https://learn.microsoft.com/en-us/azure/sre-agent/user-roles) | Reader, Standard User, Author, Administrator. Only Administrator approves actions. Author alone cannot chat or upload knowledge in the portal. |
| [Agent permissions](https://learn.microsoft.com/en-us/azure/sre-agent/permissions) | UAMI, OBO elevation, and onboarding role behavior, including subscription Monitoring Contributor. |
| [Tool access policies](https://learn.microsoft.com/en-us/azure/sre-agent/tool-access-policies) | Allow overrides Ask; a user hook returning Allow can override global Deny. |
| [Deploy with IaC](https://learn.microsoft.com/en-us/azure/sre-agent/deploy-iac) | Official Bicep, Terraform, PowerShell, and azd backends; ARM/data-plane split. |
| [API reference](https://learn.microsoft.com/en-us/azure/sre-agent/api-reference) | Preview API examples and data-plane token audience; conflicts documented below. |
| [Pricing and billing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing) | Fixed and variable billing. Stopping does not eliminate always-on cost; no rates are copied into this kit. |
| [Data privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy) | Inference can leave the selected region; provider selection requires residency review. |
| [Official repository](https://github.com/microsoft/sre-agent) | Official examples and maintained templates, not a blanket assurance of customer readiness. |
| [Pinned templates README](https://github.com/microsoft/sre-agent/blob/25a42306d298c4d28f11dd11ef9bb93cb0393be8/sreagent-templates/README.md) | AzAPI alternative and azd wrapper documented; target-RG reader assignments described. |
| [Versioned ARM definition](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents) | Resource type, names, identity, properties, and AzAPI syntax. |

The observed official repository head was
`25a42306d298c4d28f11dd11ef9bb93cb0393be8`. Only the README at that commit was
reviewed here; individual templates and recipe schemas have not been certified.
No upstream implementation has been copied or executed.

## Verified Resource Contract

- Resource: `Microsoft.App/agents`; resource-group deployment.
- ARM reference version: `2026-01-01` (non-preview version string).
- Agent name pattern: `^[A-Za-z]([-A-Za-z0-9]{0,30}[A-Za-z0-9])$`.
  It permits 2-32 characters, starts with a letter, ends alphanumeric.
- `actionConfiguration.mode` in that reference: ReadOnly, Review, Autonomous.
- `actionConfiguration.accessLevel`: Low or High.
- `upgradeChannel`: Stable or Preview.
- `defaultModel` has string `name` and `provider`; schema examples are not an
  availability guarantee. No model/provider is selected by this foundation.
- App Insights connection string and incident connection key are sensitive.
  Never put either in checked-in parameters or outputs.
- Bicep and AzAPI support are documented. Native Terraform support has not been
  verified; no fictional Terraform SRE resource will be introduced.

## Region Snapshot

The dedicated region reference lists: australiaeast, brazilsouth, canadacentral,
centralindia, centralus, eastasia, eastus2, francecentral, italynorth, japaneast,
japanwest, koreacentral, northcentralus, southafricanorth, southindia,
southeastasia, spaincentral, swedencentral, uksouth, westcentralus, westus2,
westus3. This is dated evidence, not a permanent allowlist or a subscription
eligibility check. A provider's regional resource metadata alone does not prove
that the customer's SRE Agent registration or chosen model is available.

## Product Limitations and Preview Status

1. The official repository describes a March 2026 GA launch. Do not label the
   entire product preview just because an example API is preview.
2. The API guide explicitly labels its `2025-05-01-preview` control/data-plane
   integration examples preview. Use no unvalidated preview adapter by default.
3. The ARM reference is newer than the API guide and lacks several properties
   found there. Do not transplant preview fields into the newer resource.
4. The API guide says `SRE Agent User` and describes approval permissions that
   differ from the newer user-role guide. Use the latter for persona design;
   verify actual role definitions before automation.
5. The IaC guide says hooks are data-plane-only; the API guide lists an ARM
   hooks sub-resource. The inner configuration contract is not established by
   a base64 envelope alone.
6. Review does not gate all SaaS actions. An Allow rule overrides Ask, and a
   user-defined hook Allow overrides even global Deny. Do not install generic
   Allow hooks or broad wildcard tool approvals.
7. OBO can use an Administrator's Azure permissions when UAMI access is absent.
   Refuse write elevation in Stage 0/1; low identity privileges alone are not
   a complete no-change guarantee.
8. Portal resource onboarding can grant monitoring write/operator roles.
   Reader-level onboarding must not be equated with a strictly read-only role
   inventory. Inspect effective inherited roles before first investigation.
9. Agent deployment is not proof that workload telemetry is instrumented or
   that repository, knowledge, alert routing, or audit access works.
10. An agent has one home region; moving it requires recreation. Model inference
    residency and external connector data flows need separate review.
11. Only one active incident platform, hook fail-closed behavior, data-plane
    OIDC compatibility, and individual connector schemas remain unverified.
    Do not assert them as product limits or working automation.

## Blocking Product-Contract Issues

Before Phase 3 deployment/configuration automation is released:

| Gate | Evidence required to close it |
| --- | --- |
| Version mapping | Inspect pinned official templates and reconcile supported ARM versions with provider metadata and each configuration sub-resource. |
| Read-only baseline | Show exact role inventory, including inherited roles and portal side effects; prove no subscription monitoring write grant is needed for investigation-only operation. |
| Approval enforcement | Verify global tool policy and hook schemas; negative tests must show denied writes, out-of-scope reads, external writes, and OBO write elevation are blocked. |
| Configuration schemas | Validate hooks, schedules, response plans, connectors, and repository authentication against pinned current official implementations; test preview boundaries separately. |

These are release gates, not a request for customer secrets or subscription
Owner. Phase 2 can be completed without crossing them. Do not ship empty
deployment scripts or report an untested installation as deployable.

Any unverified optional configuration must carry this exact label:
**Optional placeholder requiring validation against current Azure SRE Agent documentation.**

## Assumptions

- Commercial Azure is the initial target; sovereign availability is not implied.
- Customer supplies tenant/subscription IDs, region, and one workload RG later.
- A platform admin precreates a dedicated agent RG and registers providers when
  required. The deployer does not need subscription Owner by default.
- Existing telemetry and repository remain customer owned and must survive kit
  cleanup. New agent telemetry is separate from workload telemetry.
- Stage 0/1 are the only allowed foundation stages. Advanced autonomy is a
  future reviewed extension, not a configuration switch shipped enabled.
- Local configuration is a kit-owned schema, not an SRE Agent upload format.
- No live Azure tests are authorized in this task. Cloud checks remain NOT
  CHECKED until a disposable deployment and explicit context are supplied.

## Final Target Repository Tree

This is the full intended layout. Future paths are not present or executable
until their phase and safety gates are complete; see the README for actual status.

```text
./
  README.md, LICENSE, CONTRIBUTING.md, SECURITY.md, SUPPORT.md
  CODE_OF_CONDUCT.md, CHANGELOG.md, AGENTS.md
  .gitignore, .editorconfig, .env.example, azure.yaml
  .azure/deployment-plan.md
  docs/
    phase-1-discovery.md, sources.md, configuration.md, naming-and-tags.md
    00-solution-overview.md ... 15-faq.md
    glossary.md, decision-log.md, measurement-guide.md, release-readiness.md
    diagrams/architecture.md
  infra/
    bicep/main.bicep, main.parameters.json
      modules/{agent,identity,telemetry,rbac,diagnostics,locks,budget}.bicep
      environments/{dev,test,prod}.bicepparam
    terraform/{README.md,versions.tf,providers.tf,variables.tf,main.tf,outputs.tf}
      modules/, environments/
  config/
    schema/starter.schema.json
    {dev,test,prod}.json
    naming.json, tags.json, policy.json
  scripts/
    powershell/{Test-Configuration,Test-Repository,Test-Prerequisites,
      Deploy-Solution,Test-Deployment,Export-Solution,Update-Solution,
      Remove-Solution}.ps1
    bash/{test-prerequisites,deploy-solution,test-deployment,
      export-solution,update-solution,remove-solution}.sh
    python/
  sre-config/
    agents/, skills/, response-plans/, scheduled-tasks/, hooks/
    incident-filters/, prompts/
  knowledge-base/{architecture,runbooks,escalation,services,templates}/
  scenarios/
    core/{01-discovery,02-investigation,03-alerts,04-health-check,
      05-deployment-validation,06-knowledge,07-monitoring,08-post-incident,
      09-readiness,10-cost-hygiene}/
    advanced/{01-aks,02-network,03-data,04-multi-subscription,05-hybrid,
      06-observability,07-incident-platforms,08-github,09-agents,10-hooks}/
  tests/{unit,integration,security,smoke}/
  .github/
    workflows/{validate,deploy-dev,deploy-prod,smoke,drift,release}.yml
    ISSUE_TEMPLATE/, PULL_REQUEST_TEMPLATE.md, CODEOWNERS.example
    dependabot.yml, copilot-instructions.md
  examples/{simple-web-app,multi-tier-application,existing-environment}/
```

JSON replaces kit YAML so PowerShell can parse settings without extra modules;
it is structured, cross-platform, and schema-validatable. Product-specific
YAML, when verified, stays under sre-config and is not conflated with kit policy.

## Implementation Plan and Acceptance Criteria

| Phase | Deliverables | Acceptance |
| --- | --- | --- |
| 1 | Summary, source ledger, assumptions, limitations, tree, plan | Source conflicts and unknowns explicit; no invented contract. |
| 2 | README, architecture, Azure basics, prerequisites, schema, naming/tags, security | Offline positive/negative configuration tests and document-link checks pass. |
| 3 | Verified Bicep modules, env parameters, parity scripts, optional AzAPI | Compile, what-if, narrow roles, idempotency, inventory, opt-in lab smoke. |
| 4 | Knowledge, prompts, verified skills/agents/plans/tasks/hooks | Disabled/Review examples; negative permission and approval tests. |
| 5 | Ten core and ten optional advanced guides | Scoped inputs, evidence outputs, failure/escalation paths, test cases. |
| 6 | Governance, tests, OIDC workflows, operations | Protected production environment, static scans, no PR deployment credentials. |
| 7 | Principal security audit and release report | Commands/paths/links verified; unresolved and manual checks reported honestly. |

Cleanup will delete only verified inventory resources and exact solution-created
role/federation assignments, with dry run, explicit confirmation, and shared
resource protection. It will not rely on a name prefix or mutable tag alone.
Thirty-minute lab deployment will only be claimed after measured validation;
the foundation includes a thirty-minute preparation path, not a deployment SLA.