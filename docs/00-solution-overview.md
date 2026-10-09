# Azure SRE Agent Starter: Solution Overview

Evidence baseline: 2026-10-09. Status: Phase 2 documentation only. This is a
preparation guide, not an installable starter or permission to deploy.

## Start Here

Azure SRE Agent helps investigate service health using resource information,
telemetry, code, and operational knowledge. Its conclusions are hypotheses to
check against evidence, not a substitute for your incident commander or change
process. This kit is intended for an Azure beginner working with a platform
administrator, workload owner, and security reviewer.

The initial design is deliberately small: one agent, one non-production workload
resource group, one repository, and one existing telemetry source. Existing
applications, repositories, and telemetry remain customer owned.

1. Read [Azure basics](02-azure-basics-for-beginners.md) if tenant, subscription,
   managed identity, or RBAC are unfamiliar.
2. Complete [prerequisites](01-prerequisites.md). Record facts and blockers;
   do not create resources as part of this phase.
3. Review [architecture](03-architecture.md) with the workload owner.
4. Have a security reviewer examine [security and governance](04-security-and-governance.md),
   especially inherited permissions, external writes, and OBO.
5. Agree on [naming and tags](naming-and-tags.md), and record exceptions in the
   [decision log](decision-log.md). Use the [glossary](glossary.md) as needed.
6. Stop at the readiness boundary below. Phase 3 and later remain blocked.

**Expected evidence:** an approved scope record, named owners, a permissions
proposal, cost/privacy decisions, and an open-blocker list. None is evidence
that an agent has been installed or secured.

## What Exists and What Is Future

| Deliverable | Status | How to use it |
| --- | --- | --- |
| [Phase 1 discovery and implementation plan](phase-1-discovery.md) | Existing evidence record | Source ledger, contract conflicts, target tree, release gates |
| These eight Phase 2 documents | Documentation only | Offline learning and preparation; no cloud operations |
| Local configuration schema | Future; not implemented here | Kit-owned validation contract, not an Azure upload format |
| `config/dev.json`, `config/test.json`, `config/prod.json` | Future; not present | Separate environment settings; never secrets |
| `scripts/powershell/Test-Configuration.ps1` | Future; not present or executable | Intended positive/negative local JSON validation |
| `scripts/powershell/Test-Repository.ps1` | Future; not present or executable | Intended repository/document consistency checks |
| Infrastructure, deployment, cleanup, CI/CD | Future; blocked | Require contract validation and separate approval |
| Hooks, connectors, plans, tasks, scenario implementations | Future; blocked | Require verified schemas and security tests |

Do not run commands against the future paths. No executable local scripts are
provided or referenced as available. The full Phase 1 target tree is a roadmap,
not a list of working files. This narrower Phase 2 delivery does not satisfy the
original plan's configuration-schema and automated configuration-test acceptance
criteria; those remain pending. No thirty-minute deployment claim is made.

## Mandatory Baseline and Optional Extensions

Mandatory before a future lab: a verified tenant/subscription, one approved
non-production resource group, separate agent ownership, exact identity/role
inventory, explicit Review settings, a no-write policy, telemetry access
approval, repository read access approval, cost limits, and privacy review.
Disabled tasks and response plans are the required starting state.

Optional: additional telemetry, incident platforms, notifications, MCP servers,
multiple subscriptions, private networking, and advanced automation. For each:
**Optional placeholder requiring validation against current Azure SRE Agent documentation.**
No optional integration is installed by this phase. A connector can expose write
operations and export data even when Azure permissions are read-only.

## Starter Maturity Policy

These stages are kit policy, not Azure enum values or a product capability claim.

| Stage | Intended behavior | Current authorization |
| --- | --- | --- |
| 0: Observe | Read approved evidence and describe service health | Design only; strict no-change proof pending |
| 1: Recommend | Produce a human-reviewed diagnosis and proposed fix | Design only; no execution or OBO writes |
| 2: Approved remediation | Separately scoped, tested human-approved changes | Blocked; future security review |
| 3: Bounded automation | Narrow verified actions within explicit limits | Blocked; not a shipped setting |
| 4: Advanced autonomy | Broader operations with independently approved controls | Blocked; outside the foundation |

Review is the intended explicit setting for every future task and response plan,
not a guarantee of no changes. Product tasks and response plans default to
Autonomous. Review does not gate every external action. Allow policies override
Ask; a user-defined hook returning Allow can override even global Deny. OBO can
borrow an Administrator's Azure permissions. Stage 0/1 must reject write
elevation and cannot rely on a read-only UAMI alone.

## Preparation Workflow

| Step | Mandatory/optional | Permissions | Resources changed | Expected evidence |
| --- | --- | --- | --- | --- |
| Identify scope and owners | Mandatory | Local document access; authorized portal read access only if used | None in Azure | Tenant/subscription and workload IDs checked by two people |
| Select one existing telemetry source and repository | Mandatory | Customer-approved read access; no new tokens required now | None | Data owner, retention, sensitivity, access boundary |
| Review future role assignments | Mandatory | IAM visibility; ask administrator for redacted exports if unavailable | None | Exact scopes, inherited roles, data actions and expiry proposal |
| Review region/model and costs | Mandatory | Public documentation and approved billing visibility | None | Subscription availability still NOT CHECKED; budget owner named |
| Consider external integrations | Optional | No credentials requested or grants made | None | Explicit placeholder label and review owner |
| Accept preparation record | Mandatory | Organizational reviewers, not subscription Owner | Documents only | Blockers remain visible; deployment approval absent |

Local software installation in the prerequisite guide is optional and changes
only the workstation. A future Cloud Shell session can create storage or other
billable dependencies depending on its selected configuration; it is not part
of this offline workflow.

## Release Boundary

Phase 3+ must not be released until all four gates from Phase 1 are closed:

1. **Version mapping:** reconcile the `Microsoft.App/agents@2026-01-01` ARM
   reference with the API guide's `2025-05-01-preview` examples and pinned
   official templates. A non-preview version string and `upgradeChannel`
   Stable do not validate every connector or configuration contract.
2. **Strict read-only baseline:** inspect actual role definitions, assignments,
   inheritance, and onboarding effects. The documented portal flow assigns
   subscription Monitoring Contributor, which includes writes and blocks a
   strict Stage 0 release until a supported no-write alternative is verified.
3. **Approval enforcement:** prove denied Azure/external writes, out-of-scope
   reads, and OBO write elevation cannot proceed, including Allow/hook paths.
4. **Configuration schemas:** verify repository authentication, connectors,
   hooks, response plans, and schedules against current pinned implementations.
   Base64 encoding is not schema validation.

All live checks are **NOT CHECKED**. No IaC, deploy scripts, API payloads, role
assignments, or fictional endpoints are supplied here.

## Cost, Privacy, and Failure Handling

Preparation documents do not create Azure charges. A later agent has fixed and
variable costs; stopping it does not eliminate always-on billing. Telemetry
ingestion/retention, external services, model usage, and optional infrastructure
may add costs. Budgets notify; they are not a hard spending cap.

Logs, code, prompts, and knowledge can contain secrets or personal/customer
information. Redact evidence, minimize query time ranges, and use restricted
storage. Inference may leave the agent's home region; provider and external
connector data flows need their own residency approval.

| Problem | Safe next step | Rollback or recovery |
| --- | --- | --- |
| Missing role or inaccessible telemetry | Capture resource ID and error without credentials; ask the owner to review the minimum read role | Withdraw the access request; do not grant Contributor to bypass a 403 |
| Contract disagrees with an example | Record source/version and keep the release gate open | Do not apply the example; revert only the proposed document decision |
| Write action or OBO prompt appears | Deny and escalate; stop the investigation | Preserve audit evidence; reviewer removes only exact approved grants if any were separately made |
| Cost/residency unknown | Keep the deployment decision unapproved | Cancel the lab proposal; no cloud cleanup needed in this phase |

Never delete a shared workload or telemetry store to undo starter preparation.
Future cleanup requires verified created-resource and assignment inventories,
dry run, and explicit confirmation, not a name-prefix or tag-only match.

## Official Sources

Product claims use the [Phase 1 source ledger](phase-1-discovery.md).
Start with [overview](https://learn.microsoft.com/en-us/azure/sre-agent/overview),
[creation](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up),
[run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes),
[permissions](https://learn.microsoft.com/en-us/azure/sre-agent/permissions),
[tool policies](https://learn.microsoft.com/en-us/azure/sre-agent/tool-access-policies),
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing), and
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy).