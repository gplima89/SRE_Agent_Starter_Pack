# Azure SRE Agent Starter Kit Plan

Status: Phase 1/2 foundation and locally compiled Phase 3 Bicep baseline.
Repository regression fixed. Not ready for cloud validation or deployment.

## Scope

Build a reusable repository, not a customer deployment. No Azure resources,
credentials, commits, or remote changes are authorized by this plan.
Start with one non-production workload, one agent, one repository, and one
telemetry source. Default to read-only resource access and human review.

## Implementation Sequence

1. Verify current Microsoft Learn, official repository, and ARM schemas.
2. Record sources, assumptions, unknowns, limitations, and target tree.
3. Create beginner documentation, local configuration schema, naming and tags,
   architecture, and security baseline.
4. Implement Bicep and equivalent scripts only against verified contracts.
5. Add documented agent configuration, knowledge, prompts, and scenarios.
6. Add tests, protected OIDC workflows, operational guides, and audit report.
7. Validate locally; explicitly report checks needing customer Azure access.

## Safety Gates

- Do not infer resource properties or API paths from conceptual documentation.
- Review mode is not a replacement for read-only Azure and connector permissions.
- Never assign subscription Owner or silently register providers.
- Unknown connector schemas remain labeled, non-executable design placeholders.
- Cloud deployment requires separate tenant, subscription, scope, cost, and
  production approval. Cleanup requires a verified ownership inventory.

## Current Evidence

- Microsoft Learn overview retrieved on 2026-10-09:
  https://learn.microsoft.com/en-us/azure/sre-agent/overview
- Official repository retrieved on 2026-10-09:
  https://github.com/microsoft/sre-agent
- Versioned ARM reference verifies Microsoft.App/agents@2026-01-01; region,
  role, approval, and API source conflicts are recorded in docs/phase-1-discovery.md.
- Core resource version pinned to 2026-01-01; upstream preview fields excluded.
- Template roles verified and restricted to opt-in workload RG reader roles;
  no deployer or identity Administrator assignment. Live inherited roles and
  OBO/approval negative testing still pending.
- Configuration adapters remain blocked; no hooks, schedules, incidents enabled.
- Offline suites pass: 21 configuration, five repository regressions and 41
  compiled infrastructure checks. See docs/contract-verification.md.

## Verification

Local document links and configuration examples will be checked before handoff.
Live connector, incident, approval, and removal checks require a disposable
customer environment and must never be reported as passing without evidence.