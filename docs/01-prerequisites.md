# Prerequisites and Preparation

Status: Phase 2 documentation only; no deployment authorized. Read the
[overview](00-solution-overview.md) and [Phase 1 gates](phase-1-discovery.md)
first. This checklist prepares a future lab without creating an agent, granting
roles, registering providers, or changing a workload.

## Choose a Preparation Path

1. **Mandatory:** choose a customer-approved non-production workload and identify
   its owner. Do not use production merely because it has better telemetry.
2. **Mandatory:** choose offline preparation initially. A browser and a way to
   record the checklist are enough to read this documentation.
3. **Optional:** install local tooling from the official links below when your
   administrator permits it. Installation changes the workstation, not Azure.
4. **Optional, future lab only:** choose Azure Cloud Shell instead of a local
   shell. Review its storage, network, and billing choices before starting it.
   Do not assume every tool or the needed version is preinstalled in any shell.

**Expected evidence:** selected path, workstation OS, named platform contact,
and tools marked installed, missing, or not required. **Rollback:** cancel
optional installation or uninstall only tools you installed; preserve shared
tools and user profiles. Cloud Shell resources need separate ownership review.

## Tools and Official Installation Links

Use supported upstream releases. There is no kit-certified minimum patch
version yet. PowerShell **7** is the future cross-platform script family;
Windows PowerShell 5.1 is not a substitute. Azure CLI **2.x** is the upstream
CLI family, not an invented kit compatibility floor. Record actual versions
and validate them when implementation exists.

| Tool | Required now? / future purpose | Windows | macOS | Linux |
| --- | --- | --- | --- | --- |
| Git | Optional now; future version control | [Install](https://git-scm.com/downloads/win) | [Install](https://git-scm.com/downloads/mac) | [Install](https://git-scm.com/downloads/linux) |
| PowerShell 7 | Optional now; future PowerShell validation/deploy parity | [Install](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) | [Install](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos) | [Install](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux) |
| Azure CLI 2.x | Optional now; future approved Azure checks | [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows) | [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos) | [Install options](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux) |
| Bicep CLI | Optional; future primary IaC compilation, blocked by release gates | [Official installation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) | [Official installation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) | [Official installation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) |
| Azure Developer CLI (azd) | Optional; future verified wrapper, not required for this phase | [OS installation choices](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) | [OS installation choices](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) | [OS installation choices](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) |
| Terraform | Optional; future AzAPI parity only, not an assumed native SRE resource | [Official installation](https://developer.hashicorp.com/terraform/install) | [Official installation](https://developer.hashicorp.com/terraform/install) | [Official installation](https://developer.hashicorp.com/terraform/install) |

Cloud Shell has different launch and persistence behavior from a workstation:
use the [overview](https://learn.microsoft.com/en-us/azure/cloud-shell/overview),
[PowerShell quickstart](https://learn.microsoft.com/en-us/azure/cloud-shell/quickstart-powershell),
[Bash quickstart](https://learn.microsoft.com/en-us/azure/cloud-shell/quickstart),
and [included tools reference](https://learn.microsoft.com/en-us/azure/cloud-shell/features).
Check the actual session, including Git, PowerShell, Azure CLI, Bicep, azd,
Terraform, and any future helper dependency before relying on it. Cloud Shell
is not an offline prerequisite and may need access to storage or network
resources. Do not install tools into a managed session without owner approval.

1. Follow the installation page for your OS and organization-approved package
   source. Use the OS-specific verification step on that page.
2. Record tool name, actual version, installation source, and verification date.
   A screenshot or redacted version output is sufficient; no token output.
3. Open a fresh terminal if the install updated PATH. Confirm PowerShell is
   `pwsh`/7 rather than the legacy Windows PowerShell executable.
4. Leave optional tools absent if you do not need their future workflow. Do not
   add Python, Kubernetes tooling, or extensions solely for these documents.

**Permissions:** workstation software-install approval; no Azure role for a
local install. If installation needs elevation, the user or desktop admin
handles it directly. **Resources changed:** binaries, packages, and possibly
PATH. **Cost/privacy:** software may be free to install but organizational
licensing and package-source rules still apply; login caches are sensitive.

## Mandatory Scope Record

Keep identifiers in an access-controlled preparation record. IDs are not
passwords, but can reveal tenant structure. Do not paste tokens, App Insights
connection strings, incident keys, or customer log samples into Git.

| Field | What to record | Expected evidence / approver |
| --- | --- | --- |
| Tenant | Directory ID and display name | Platform owner confirms correct work/school directory |
| Subscription | ID, name, environment, billing owner | Platform and cost owners confirm non-production scope |
| Workload RG | Full resource-group ID and workload owner | Existing resource inventory; no inferred access from its name |
| Agent RG | Proposed dedicated group and owner; future precreation | Platform-admin responsibility, not a create step now |
| Region | Candidate home region, availability/residency status | Current region docs plus later subscription creation-picker evidence |
| Model/provider | Decision pending or approved provider with residency rationale | No hardcoded model; subscription/region availability later verified |
| Telemetry | One existing workspace or App Insights resource ID | Data owner, table/resource access boundary, retention and ingestion status |
| Repository | One repository and approved branch/content scope | Repo owner approves read-only integration; authentication not yet configured |
| Human roles | Investigator, author, approver, auditor, IAM operator | Scope and duration proposal from security matrix |
| Identities | Proposed UAMI workload access; SAMI infrastructure | Separate responsibilities; exact deployed IDs unavailable until future lab |
| Cost/privacy | Budget owner, spending envelope, sensitivity, region/data-flow decision | Written approval; budget is not a hard cap |
| Gates | Version, read-only, approval, configuration status | All open until tested; no implied deployment approval |

## Numbered Readiness Steps

These are record-and-inspect steps. Do not select Create, Save, Add role
assignment, Register, or an auto-assignment banner while inspecting the portal.
If you have no approved Azure access, obtain redacted evidence from the owner
instead; all cloud checks in this repository remain NOT CHECKED.

1. **Verify context.** In the Azure portal, inspect the selected directory and
   subscription; compare both IDs with the scope record. Permission: approved
   directory/subscription visibility. Evidence: two-person confirmation.
   Changes: none. Recovery: switch context before continuing; never broaden
   access just to see a missing subscription.
2. **Verify workload boundary.** Inspect the existing workload RG Overview and
   inventory. Permission: Reader at that group or owner-provided evidence.
   Evidence: resource IDs and owner confirmation. Changes: none. Recovery:
   choose a smaller approved non-production group if unrelated services share it.
3. **Verify usable telemetry.** Ask the telemetry owner for a bounded, redacted
   query result or metric time window showing recent workload data. Permission:
   separately approved telemetry read access; RG Reader alone may not suffice.
   Evidence: timestamps, source ID, query/time window, retention and ingestion
   delay. Changes: none; adding instrumentation is outside this phase. Recovery:
   record missing data and defer agent use rather than enable new diagnostics.
4. **Verify code access intent.** Have the repo owner approve the exact repository
   and branch/content boundary. Permission: existing repo read access or owner
   confirmation. Evidence: sensitivity review and read-only authentication plan.
   Changes: none; no credential creation. Recovery: use sanitized knowledge
   later if code cannot be shared; do not issue a broad write token.
5. **Inspect IAM proposal.** Review scope inheritance and data actions using
   [security and governance](04-security-and-governance.md). Permission: IAM
   read visibility or administrator-provided exports. Evidence: current roles
   plus proposed role/scope/expiry records. Changes: none. Recovery: reject
   subscription Monitoring Contributor and other writes as a Stage 0 baseline;
   the supported alternative is still a release blocker, not an assumed fix.
6. **Review region, pricing, and privacy.** Read current official sources with
   the cost and data owners. Permission: public docs and authorized billing
   views. Evidence: cost categories, approved residency and unresolved model
   availability. Changes: none. Recovery: leave deployment unapproved when
   residency or costs cannot be bounded.
7. **Sign preparation, not deployment.** Mark missing items BLOCKED, supplied
   documentary evidence REVIEWED, and unrun live checks NOT CHECKED. Permission:
   organizational reviewers. Evidence: dated scope and gate record. Changes:
   documents only. Recovery: withdraw an outdated decision; no Azure rollback
   is required for this preparation.

## Permissions You Must Not Add by Default

There is no automatic subscription Owner grant in this kit. Provider
registration and a future dedicated RG are platform-admin tasks, separately
authorized and scoped. RBAC assignment authority is separate from deployment
authority: Contributor cannot automatically assign roles, and Azure Owner or
Contributor does not replace SRE Agent data-plane user roles.

The documented creator receives SRE Agent Administrator, which needs review
and possible later removal by an authorized IAM operator. Choosing the portal's
Reader permission level does not establish a read-only role inventory: the
documented subscription Monitoring Contributor grant includes monitoring
writes. Do not complete onboarding and call it compliant without inspection.

## Common Errors

| Symptom | Likely cause | Safe response |
| --- | --- | --- |
| Tool not found after install | PATH/session or unapproved installation | Follow upstream verification; reopen terminal; no cloud changes |
| Legacy PowerShell opens | Windows PowerShell 5.1 selected | Select the installed PowerShell 7 executable; no unsupported version claim |
| Subscription missing | Wrong tenant, membership, or scope | Ask platform owner; do not request Owner as a shortcut |
| Agent portal 403 | Missing SRE data role; Author alone cannot chat/upload knowledge | Verify exact human role before investigating networking or secrets |
| Metrics/logs empty | Wrong source/time range, ingestion delay, missing instrumentation | Ask workload owner; do not enable collection without cost/privacy approval |
| Agent/model unavailable | Subscription or region eligibility | Keep availability NOT CHECKED until approved live inspection |
| Example fields rejected | Preview/current ARM contract mismatch | Keep Phase 3 blocked; do not substitute guessed API properties |

## Future Local Validation Contract

Future `config/dev.json`, `config/test.json`, and `config/prod.json` will be
kit-owned JSON, not ARM or SRE Agent data-plane payloads. Future
`scripts/powershell/Test-Configuration.ps1` and
`scripts/powershell/Test-Repository.ps1` will validate local settings and
repository consistency. They do not exist or run in this phase. Positive and
negative configuration tests, compatibility certification, compilation, and
live permission/approval tests remain pending. Production settings do not
authorize production use.

## Official Sources

See [Phase 1 sources and gates](phase-1-discovery.md),
[create and set up](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up),
[supported regions](https://learn.microsoft.com/en-us/azure/sre-agent/supported-regions),
[user roles](https://learn.microsoft.com/en-us/azure/sre-agent/user-roles),
[agent permissions](https://learn.microsoft.com/en-us/azure/sre-agent/permissions),
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing), and
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy).
Installation links above are upstream guidance, not evidence of kit testing.