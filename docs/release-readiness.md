# Release Readiness: Foundation Only

Review date: 2026-10-09. Verdict: **NOT READY for deployment or production**.
Phase 1/2 foundation and locally compiled Phase 3 Bicep baseline are implemented;
deployment/lifecycle automation and Phases 4-7 remain incomplete. No customer Azure
resources were created, tested, changed, or removed. No commits/pushes performed.

## Confirmed Corrections

| File | Problem addressed | Correction and regression check |
| --- | --- | --- |
| phase-1-discovery.md and contract-verification.md | Conceptual/preview examples could be mistaken for the current schema. | Explicit 2026-01-01 core contract, exclude preview fields, inspect pinned source, compile without warning suppression; 41 compiled-template checks. |
| 04-security-and-governance.md | Review or Reader onboarding could be mistaken for complete write prevention. | Explain task/plan Autonomous defaults, external writes, OBO, monitoring grants, and hook/policy precedence. Runtime negative checks remain required. |
| starter.schema.json and Test-Configuration.ps1 | Unsafe local intent could silently enable autonomy or broaden scope. | Require Review, stages 0/1, empty actions, disabled automation, one RG, matching subscription/tags, separate agent RG. Unit tests reject unsafe settings. |
| README.md | Repository could imply absent scripts or production deployment readiness. | List implemented commands only; explicit blocker and no azd up instruction. Local path check covers referenced files. |
| Test-Repository.ps1 | Absolute-path exclusions silently skipped fixtures below AppData/Local and any repository under a local parent. | Match exclusions relative to RepositoryRoot; five tests cover code examples, broken links, credential detection, local parent and config/local. No tests weakened. |
| configuration.md | Retention range or offline PASS could imply Azure support. | Distinguish kit limits and intent checks from provider constraints and live readiness. |
| infra/bicep/main.bicep and modules/workload-readers.bicep | Blindly reusing upstream would introduce preview fields, UAMI Administrator grants and SAMI grants outside skip-RBAC guard. | Dedicated RG, Low/Review, no Admin grants, optional reader-only grants for both identities obey same condition. Compiled tests check scopes and allowlist. |
| infra/bicep/modules/agent.bicep | Sensitive telemetry could leak through outputs or checked-in parameters. | Secure connection-string input, resource reference in parent, non-sensitive outputs; compiled secure-parameter check. |
| Test-Infrastructure.Tests.ps1 | ARM resource dictionaries and build-params wrapper differ from naive array/parameter assumptions. | Normalize arrays/dictionaries, resolve compiled role variables, parse parametersJson; all 41 checks pass. |

## Local Checks

- Configuration unit suite: 21 checks passed in PowerShell 7 on Windows.
- Configurations dev/test/prod: passed schema and policy checks.
- Repository checker regression: five checks PASS, including real broken links
  and credentials in fenced code. Parent directory names no longer skip scans.
- Repository checker: PASS for local Markdown file paths, PowerShell syntax and
  selected credential patterns. A dedicated secret scanner is still required.
- Bicep root and modules compile; dev/test/prod parameter examples compile with
  synthetic process inputs; 41 infrastructure assertions PASS.
- External source pages used in discovery: retrieved directly. All external
  links and Markdown anchor existence: NOT CHECKED by the local checker.
- Terraform/shell/Python: NOT CHECKED; no implementation yet.
- Live roles, idempotency, drift, connector failure, missing telemetry, OBO,
  denied actions, audit access, schedules, alerts, cleanup: NOT CHECKED.
- Heuristic credential scan is limited to selected text extensions. It does not
  prove absence of arbitrary secrets, binary credentials, or historical leaks.

Run in PowerShell 7 at root:

```powershell
./scripts/powershell/Test-Repository.ps1
./tests/unit/Test-Configuration.Tests.ps1
./tests/unit/Test-Repository.Tests.ps1
./tests/unit/Test-Infrastructure.Tests.ps1
```

## Manual Customer Decisions

Tenant/subscription, workload RG, region eligibility, model/provider residency,
repo authentication owner, telemetry access, data classification, retention,
network/DNS/firewall access, business/technical owners, cost budget, support
contact, and production approvers. Do not publish those details in issues.

## Remaining Release Gates

See [current contract verification](contract-verification.md) for the resolved
core resource/role-template gates and outstanding runtime gates.
Implement prerequisite and lifecycle automation with ownership inventory,
explicit context, dry-run/what-if, confirmation and shared-resource protection.
Validate effective roles and OBO/tool governance in a disposable environment;
complete parity automation. Next add verified agent assets and all scenarios, CI/OIDC
protection, lifecycle inventory/confirmation, and operational documentation.
Do not create placeholder scripts that return success for missing behavior.

The definition of done for the complete starter has **not** been met. This report
records a usable offline foundation and why a cloud installation cannot yet be
claimed. Local compilation resolves the core resource syntax choice, but cannot
prove provider availability, live permissions, or approval controls.