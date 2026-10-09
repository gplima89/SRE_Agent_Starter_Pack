# Deploy Through Azure Portal

The README button opens Azure Portal's standard custom deployment form. Bicep
remains the source; Azure Portal downloads the compiled ARM JSON with embedded
modules. No local HTML form, Git clone, or PowerShell installation is required
for the operator. This is an unverified lab foundation, not a production release.

## Before You Click

- Use an approved disposable subscription/resource group and record a cleanup owner.
- Confirm SRE Agent eligibility, provider registration, region/model availability,
  data residency, organizational policies, and an approved cost estimate.
- Choose monitoring ownership: **Create new** (default) creates a workspace and
   Application Insights in the agent group; **Use existing** requires a component
   already present in the selected subscription. Confirm monitoring region support
   and register `Microsoft.Insights` and `Microsoft.OperationalInsights` as needed.
- Obtain scoped deployment permissions: resource writes and
   `Microsoft.Resources/deployments/*` on the agent group. Create mode also requires
   `Microsoft.OperationalInsights/workspaces/write` and
   `Microsoft.Insights/components/write` there. Reuse mode requires permission to
   read the existing telemetry properties, including its connection string.
   Creating a group also requires resource-group write permission
  at subscription scope. Do not grant subscription Owner as a shortcut.
- Optional workload grants require `Microsoft.Authorization/roleAssignments/write`
  on that workload group. Leave the option false unless explicitly approved.

See [prerequisites](01-prerequisites.md), [security](04-security-and-governance.md),
and [contract verification](contract-verification.md) for the unresolved gates.

## Portal Steps

1. Click **Deploy to Azure** in the README and sign in with the approved account.
2. Check the directory and subscription. Portal uses the selected subscription;
   local Azure CLI context and config JSON files do not control this deployment.
3. Select a dedicated agent resource group, or choose **Create new** and name it.
   Do not deploy into a shared workload or monitoring group.
4. Complete the inputs below. Descriptions are included in the template.
5. Review the template, costs, changes and organizational approval before choosing
   **Review + create**. Portal validation is not the kit's live preflight or a
   reviewed what-if. Do not continue if required checks or values are unresolved.
6. Only after approval, choose **Create** yourself. Inspect deployment operations
   and outputs, then run your organization's acceptance/security checks before use.

| Input | Meaning |
| --- | --- |
| Agent Name | Unique agent name; 2-32 characters, start with a letter, end with a letter or number, use letters/numbers/hyphens. |
| Location | Confirmed agent region identifier. The resource group's metadata location is not an availability check. |
| Environment | dev/test/prod tag; defaults to dev. prod is not a readiness certification. |
| Workload Name | Workload tag, not a scope or automatic naming rule. |
| Cost Center, Business Owner, Technical Owner | Approved non-sensitive team/allocation labels, not credentials or role assignments. |
| Data Classification | Classification tag; does not enforce protection. |
| Monitoring Mode | Create new (default) or Use existing. New resources use the agent group and Location. |
| Application Insights Resource Group Name / Name | Leave empty for Create new; ignored in that mode. Both are required for Use existing and identify a component in the selected subscription. No connection string input. |
| Model Provider / Model Name | Exact verified identifiers for this subscription/region. No guessed defaults or availability allowlist. |
| Workload Resource Group Name | Optional single existing group, separate from the agent group; empty means no workload scope. |
| Assign Workload Reader Roles | Defaults false. Approved true requires a nonempty workload group and grants only Reader/Log Analytics Reader to both identities there. |

The standard form does not enforce every cross-field rule from the offline setup
validator. You must reject the agent group as a workload group and a reader opt-in
with no workload group before deploying. ARM syntax validation is not policy approval.

## Monitoring Choices

**Create new** creates `<agentName>-logs` (Log Analytics) and `<agentName>-appi`
(workspace-based Application Insights), with the same ownership tags and region
as the agent. Application Insights waits for the workspace, and the foundation
waits for Application Insights before reading its properties. The connection
string stays internal and is passed through a secure module parameter, never an
output. `applicationInsightsId` identifies the selected component in either mode.

These declarations use create-or-update semantics, not an existence guard.
Before the first deployment, confirm those derived names do not belong to unrelated
resources. A retry with the same names updates matching resources. Review a
what-if before retrying, especially after a partial failure or manual changes.

The workspace uses pay-as-you-go (`PerGB2018`) and a **30-day workspace default**.
This is not a promise that all telemetry is deleted after 30 days: Application
Insights tables have documented **90-day defaults**, and table-level settings
can differ. The template does not set table retention or immediate purge.
Approve and inspect actual table retention for privacy requirements. Ingestion
and retention are billed through Log Analytics. No budget, cost alert, daily cap,
or spending ceiling is configured; stopping the agent is not monitoring cleanup.

This lab enables public monitoring ingestion/query endpoints and retains service
authentication defaults. It does not add private endpoints or enforce Entra-only
telemetry ingestion; SRE Agent compatibility with stricter ingestion authentication
has not been verified. Reject this route if those settings violate organizational
policy. No additional monitoring RBAC grants or workload log connectors are added.

**Use existing** deploys neither monitoring resource and does not change existing
tags, workspace linkage, network settings, retention, or pricing. Enter both existing
component names; the nested foundation rejects empty names. A new empty agent group
cannot contain an existing component. Existing telemetry remains externally owned.
Changing from Create new to Use existing in an incremental deployment does not
delete the previously created monitoring or move historical data.

The core Bicep, offline generator, and environment parameter files remain reuse-only;
this monitoring choice belongs to the Portal wrapper.

## Safety And Recovery

The compiled foundation fixes the agent to **Low**, **Review**, and **Stable**.
It creates one agent and one user-assigned identity, plus the two monitoring
resources in Create new mode (or reuses Application Insights in Use existing mode),
and does not install connectors, schedules, incidents, repository integration,
agent-user grants, or write roles. Runtime/OBO behavior remains unverified.

A failed deployment may leave resources and charges. Record deployment operations
and resource IDs, and inspect what was actually created. There is no automated
cleanup script yet. Do not delete a shared group, reused monitoring, or preexisting
resources. Newly created monitoring is owned by this lab deployment, but deletion
requires owner approval and a check for other consumers and retention obligations.
Deleting a dedicated agent group also deletes monitoring inside it, including any
reused component located there; never treat reused resources as disposable.
Optional workload role assignments are outside the agent group and
need separate ownership review. Redeploying with false does not remove existing
assignments; an incremental ARM deployment is not a cleanup operation.

## Configuration And Publication

Portal inputs go directly to ARM; they do not write dev/test/prod JSON or
Bicep parameter files back to GitHub. The [offline setup form](../tools/setup.html)
and [generator](../scripts/powershell/New-SetupConfiguration.ps1) remain optional
planning tools for advanced workflows, not prerequisites for the button.

The button initially targets the public raw JSON on `main`. It cannot fetch these
local files, and private GitHub authentication is not handled by this button.
This change does not publish a commit or deploy any resources. Once published,
verify the public URL returns JSON and opens the intended Portal parameter form.
Do not press Create merely to test the form.

For an approved release, replace `/main/` in the raw URL with the full reviewed
commit SHA, URL-encode it, and append it to
`https://portal.azure.com/#create/Microsoft.Template/uri/`.
The pinned commit must already contain the artifact. Fork maintainers must change
the owner/repository in the button too. No release SHA is invented here.

## Maintainer Checks

Use PowerShell 7, Azure CLI and **Bicep 0.43.8**, the version used for this artifact.
Run from the repository root:

```powershell
./scripts/powershell/Build-PortalTemplate.ps1
./scripts/powershell/Build-PortalTemplate.ps1 -Check
./tests/unit/Test-PortalTemplate.Tests.ps1
./tests/unit/Test-Infrastructure.Tests.ps1
./scripts/powershell/Test-Repository.ps1
```

These are local-only checks; the build may download pinned public AVM modules.
`-Check` fails on artifact drift. Commit source and regenerated JSON together.
The CI workflow performs offline compilation/freshness checks without Azure login,
cloud credentials, deployment, or OIDC. Live region/model/RBAC/Policy/runtime and
cleanup validation still need an approved environment and release evidence.

Official reference: [Deploy to Azure button](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-azure-button).

Monitoring contracts and behavior:
- [Application Insights components, 2020-02-02](https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/2020-02-02/components).
- [Log Analytics workspaces, 2025-07-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/2025-07-01/workspaces).
- [Workspace-based Application Insights creation and billing](https://learn.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource).
- [Workspace and table retention](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-retention-configure).
- [Azure Monitor pricing](https://azure.microsoft.com/pricing/details/monitor/).