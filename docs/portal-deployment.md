# Deploy Through Azure Portal

The README button opens Azure Portal's standard custom deployment form. Bicep
remains the source; Azure Portal downloads the compiled ARM JSON with embedded
modules. No local HTML form, Git clone, or PowerShell installation is required
for the operator. This is an unverified lab foundation, not a production release.

## Before You Click

- Use an approved disposable subscription/resource group and record a cleanup owner.
- Confirm SRE Agent eligibility, provider registration, region/model availability,
  data residency, organizational policies, and an approved cost estimate.
- Prepare an existing Application Insights component in the same subscription.
  A newly created empty agent group cannot contain that existing component.
- Obtain scoped deployment permissions: resource writes and
  `Microsoft.Resources/deployments/*` on the agent group, plus permissions to
  read the existing telemetry properties. Review the access needed to read its
  connection string. Creating a group also requires resource-group write permission
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
| Application Insights Resource Group Name / Name | Existing telemetry group/component names in the selected subscription. No connection string input. |
| Model Provider / Model Name | Exact verified identifiers for this subscription/region. No guessed defaults or availability allowlist. |
| Workload Resource Group Name | Optional single existing group, separate from the agent group; empty means no workload scope. |
| Assign Workload Reader Roles | Defaults false. Approved true requires a nonempty workload group and grants only Reader/Log Analytics Reader to both identities there. |

The standard form does not enforce every cross-field rule from the offline setup
validator. You must reject the agent group as a workload group and a reader opt-in
with no workload group before deploying. ARM syntax validation is not policy approval.

## Safety And Recovery

The compiled foundation fixes the agent to **Low**, **Review**, and **Stable**.
It creates one agent and one user-assigned identity, reuses Application Insights,
and does not install connectors, schedules, incidents, repository integration,
agent-user grants, or write roles. Runtime/OBO behavior remains unverified.

A failed deployment may leave resources and charges. Record deployment operations
and resource IDs, and inspect what was actually created. There is no automated
cleanup script yet. Do not delete a shared group, reused monitoring, or preexisting
resources. Optional workload role assignments are outside the agent group and
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