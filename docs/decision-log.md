# Decision Log

Recorded: 2026-10-09. Scope: starter-kit design, not customer deployment
authorization. The [Phase 1 discovery](phase-1-discovery.md) is the evidence
baseline. The earlier discovery-only plan is not a certification of contracts.
These records distinguish agreed kit policy from unresolved product behavior.

## Status and Decision Authority

- **Accepted design:** a policy or documentation choice, not a tested feature.
- **Blocked:** insufficient evidence to release implementation.
- **Deferred:** optional or later work not authorized by this phase.
- **Superseded:** retain the old record and link to its replacement; do not erase
  a security-relevant decision history.

The roles below are review responsibilities, not grants already made to named
people. A release needs dated evidence and actual approvers. No customer Azure
context has been supplied; live checks are NOT CHECKED.

## Decisions

| ID / date | Status | Decision and rationale | Review owner | Consequence / evidence needed |
| --- | --- | --- | --- | --- |
| D01 / 2026-10-09 | Accepted design | Begin with one non-production workload RG, one agent, one repository, one existing telemetry source | Workload/platform owners | Small, inspectable scope; shared resources retained; no subscription-wide reads by default |
| D02 / 2026-10-09 | Accepted design | Phase 2 is only the eight owned documentation files | Kit maintainer | No README/Phase 1/plan changes, schema, scripts, IaC, credentials, commits or deployment; original schema/test acceptance remains pending |
| D03 / 2026-10-09 | Accepted design | Stage 0 observes and Stage 1 recommends; no workload or external writes | Security/workload reviewers | Internal threads/usage are distinct; no OBO write approval even for a lab |
| D04 / 2026-10-09 | Accepted design | All future plans/tasks explicitly Review and initially disabled | Security/authoring reviewers | Product defaults Autonomous; future validation must reject absent/unsafe settings and inspect effective state |
| D05 / 2026-10-09 | Accepted design | Layer RBAC, source permissions, policies, hooks, OBO governance, and audit | Security reviewer | Review is not an external-write gate; Allow beats Ask; user-hook Allow can override global Deny |
| D06 / 2026-10-09 | Accepted design | UAMI for workload access and documented connector auth; SAMI for infrastructure | Platform/IAM reviewer | Verify exact principals/grants; no workload-role duplication on SAMI; managed identity does not imply read-only |
| D07 / 2026-10-09 | Accepted design | Human personas follow current user-role guide, not older API terminology | IAM/agent governance reviewers | Reader/Standard User/Author/Administrator; only Admin approves/OBO; Author alone lacks portal chat/knowledge/repo access |
| D08 / 2026-10-09 | Accepted design | No automatic subscription Owner; platform precreates agent RG/registers providers later | Platform/IAM reviewer | Deployment and role-assignment privileges separate, scoped and time-bound; creator Admin side effect inspected |
| D09 / 2026-10-09 | Blocked | Reconcile 2026-01-01 ARM reference with 2025-05-01-preview API/examples | Contract maintainer | Inspect pinned individual templates and provider metadata; no property transplantation or guessed version mapping |
| D10 / 2026-10-09 | Blocked | Strict no-write baseline must exclude documented subscription Monitoring Contributor | Security/platform reviewers | Portal Reader-level onboarding includes write role; inspect before/after roles and prove supported no-write alternative, not silent removal |
| D11 / 2026-10-09 | Blocked | Verify tool-policy/hook contracts and approval enforcement | Security/contract reviewers | Negative Azure/external write, out-of-scope read, OBO and override tests; timeout/failure behavior not assumed |
| D12 / 2026-10-09 | Blocked | Validate configuration schemas/auth for hooks, connectors, plans/tasks/repositories | Contract/integration owners | IaC guide data-plane hooks versus API ARM hook listing conflict; base64 envelope is not schema proof |
| D13 / 2026-10-09 | Accepted design; implementation blocked | Bicep primary, AzAPI only for verified same-operation parity | Infrastructure maintainer | No fictional native Terraform SRE resource; upstream IaC/azd support does not prove kit implementation |
| D14 / 2026-10-09 | Deferred | Use future kit-owned JSON config and local validation | Kit maintainer | Future dev/test/prod.json plus Test-Configuration.ps1/Test-Repository.ps1; not present/executable or Azure upload formats |
| D15 / 2026-10-09 | Accepted design | Naming prefixes and operational tags are kit conventions | Platform/cost owners | Agent name obeys ARM 2-32 pattern; tags/names are neither authorization nor sufficient cleanup ownership |
| D16 / 2026-10-09 | Blocked for live use | Region/model, inference residency, source data and cost approval are customer decisions | Privacy/cost/platform owners | No model chosen; region list is dated, not eligibility proof; stopping does not remove always-on cost |
| D17 / 2026-10-09 | Deferred | Additional incident platforms, notifications, MCP, networking and advanced stages | Integration/security owners | Each unverified optional design carries exact placeholder label; no schemas or limits claimed |
| D18 / 2026-10-09 | Accepted design | Cleanup uses verified inventory of created resources and exact grants | Platform/IAM/workload owners | Dry run, confirmation, preserve shared data; deletion cannot undo workload/external writes |
| D19 / 2026-10-09 | Accepted design | Product GA and preview examples are distinct | Maintainer | Official repository reports March 2026 GA; preview integration examples remain explicit; Stable channel does not close contract gates |

## Release-Gate Ledger

| Gate | Current state | Required evidence | What does not close it |
| --- | --- | --- | --- |
| Version mapping | BLOCKED; live NOT CHECKED | Exact pinned templates, provider/API availability, field and configuration-surface mapping | A newer ARM page, GA label, Stable channel, or a successful base-resource creation |
| Read-only baseline | BLOCKED; live NOT CHECKED | Actual role definitions, assignment/inheritance inventory, onboarding delta, supported investigation without monitoring writes | Portal Reader label, narrow UAMI Reader grant hiding inherited roles, or denying one OBO prompt |
| Approval enforcement | BLOCKED; live NOT CHECKED | Negative tests across Azure/external tools, thread/custom Allow, user-hook overrides, OBO, failures, with unchanged canary state | Review alone, prompt instructions, or a test run by an unprivileged user only |
| Configuration schemas | BLOCKED; live NOT CHECKED | Verified current pinned auth/payload contracts and response/effective-state tests for each enabled feature | Guessed endpoints, empty stubs, a base64 wrapper, or copying a preview property into 2026-01-01 |

The official repository head observed by Phase 1 was
`25a42306d298c4d28f11dd11ef9bb93cb0393be8`; only its templates README was
reviewed in that evidence baseline. Individual templates were not certified.
Do not rely on older session notes claiming tested schemas, Review task
defaults, absent azd support, or no contradictions; those claims conflict with
the controlling discovery record and current product guidance.

## How to Propose a Change

1. **Mandatory:** identify the decision/gate and explain the new evidence, with
   official source URL, version/commit, review date, and exact affected surface.
2. **Mandatory:** state what resources and permissions would change, including
   inheritance, connector tools, OBO-capable humans, and secret handling.
3. **Mandatory:** state expected evidence, failure cases, independent negative
   tests, cost/privacy impact, and rollback using recorded prior state.
4. **Mandatory:** obtain separate platform, workload, security, data/privacy,
   and cost approval as applicable. Do not treat a code review as Azure change
   authorization or a grant of subscription Owner.
5. **Mandatory:** record result as reviewed/pending/blocked until actual tests
   supply evidence. Supersede records explicitly instead of silently rewriting
   a previously accepted no-write policy.
6. **Optional:** propose an extension, but keep it disabled/design-only and label:
   **Optional placeholder requiring validation against current Azure SRE Agent documentation.**

**Permissions now:** local document review only; owner-supplied redacted records
if cloud context is relevant. **Resources changed now:** proposed documentation
only. **Expected evidence:** dated proposal, evidence links, reviewers, open
tests. **Common errors:** treating supplied examples as validated contracts or
closing a gate because an agent deploys. **Rollback:** withdraw/supersede the
decision; no cloud cleanup in Phase 2. **Costs/privacy:** no cloud resource
creation here; evidence should omit credentials and confidential raw logs.

## Change Record Template

Use this non-executable template in an approved record; do not put secrets in it.

```text
Decision ID and date:
Status (proposed / accepted design / blocked / deferred / superseded):
Problem and affected environment/resource IDs:
Mandatory or optional:
Official evidence URLs, versions/commits, and review date:
Options considered and reason for selection:
Permissions (principal, role, scope, duration, inheritance):
Resources changed and previous state:
Costs, data destinations, sensitivity, retention, and privacy approval:
Expected positive/negative evidence and current NOT CHECKED tests:
Failure/stop conditions and rollback owner/procedure:
Named reviewers and separate change authorization:
Supersedes / unresolved gates:
```

## Official Sources

See [Phase 1 discovery and source ledger](phase-1-discovery.md),
[ARM 2026-01-01](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents),
[API guide](https://learn.microsoft.com/en-us/azure/sre-agent/api-reference),
[IaC guide](https://learn.microsoft.com/en-us/azure/sre-agent/deploy-iac),
[pinned templates README](https://github.com/microsoft/sre-agent/blob/25a42306d298c4d28f11dd11ef9bb93cb0393be8/sreagent-templates/README.md),
[user roles](https://learn.microsoft.com/en-us/azure/sre-agent/user-roles),
[permissions](https://learn.microsoft.com/en-us/azure/sre-agent/permissions),
[run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes),
[tool policies](https://learn.microsoft.com/en-us/azure/sre-agent/tool-access-policies),
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing), and
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy).