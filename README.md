# Azure SRE Agent Starter Kit

A reusable, beginner-oriented foundation for safe Azure SRE Agent adoption.
Start with one non-production workload, one agent, one code repository, one
telemetry source, and one reproducible operational problem.

> **Current status: locally compiled foundation with a Portal lab deployment entry point.
> Not live-validated or production ready.** The button does not resolve the
> contract and security gates in [Phase 1](docs/phase-1-discovery.md).
> Cleanup, cloud prerequisite checks, and live smoke tests remain unfinished.
> There is no azure.yaml; do not run azd up here.

## Deploy Through Azure Portal

**Lab preview only.** Read the [Portal deployment guide](docs/portal-deployment.md)
before proceeding. Deployment creates billable resources and may fail eligibility,
region, model, policy, or permission checks. Use an approved disposable environment.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fgplima89%2FSRE_Agent_Starter_Pack%2Fmain%2Finfra%2Fportal%2Fazuredeploy.json)

Select your subscription, choose an existing dedicated agent resource group or
**Create new**, and fill in the parameters in Azure Portal. **Monitoring Mode**
defaults to **Create new**, provisioning Application Insights and a Log Analytics
workspace in the agent group. Leave the existing telemetry fields empty for this
mode. Choose **Use existing** to reuse a component in the same subscription.
Monitoring ingestion/retention may incur charges. Keep workload reader grants off
initially. Git, PowerShell, and the local HTML form are not required for this route.

The Portal template grants **SRE Agent Administrator on the agent only** to the
deploying user by default. Deployment requires scoped role-assignment write
permission, even with workload readers off. For automation or another setup owner,
supply the intended human user/group Entra object ID and matching principal type.
See [agent user access](docs/portal-deployment.md#agent-user-access) for permissions,
propagation, and existing-deployment recovery.

The button works only after these files are published to the public GitHub repository.
It currently follows `main`, not a release; use a reviewed immutable commit URL for
reproducible deployments. Portal inputs do not update repository configuration files.

## What Is Available

- Verified source ledger, product limitations, assumptions, and full target tree.
- Beginner Azure, prerequisite, architecture, naming/tagging, and security guides.
- Safe fictional dev/test/prod configuration with a kit-owned JSON Schema.
- Offline validation and regression tests; no Azure login or secrets required.
- A compiled resource-group Bicep baseline using the documented 2026-01-01
	agent contract, pinned identity/role AVMs, and existing telemetry.
- A Portal wrapper with optional monitoring creation; offline configuration paths
	still require existing telemetry.
- A documented release gate rather than invented Azure APIs or unchecked recipes.

The schema is **not** an Azure SRE Agent configuration upload. Selecting a
deploymentMode does not implement or execute that backend. Stage 0/1, Review,
empty action lists, and disabled automation are enforced locally. These settings
do not install or prove runtime security controls in Azure.

## Offline Preparation

This is a preparation path, not a claim that a cloud deployment takes 30 minutes.

1. Install [Git](https://git-scm.com/downloads) and
	[PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
	for your OS. Windows PowerShell 5.1 is not sufficient for the validator.
2. Clone or fork this repository. In PowerShell 7 on Windows, macOS, or Linux:

	```powershell
	git clone https://github.com/gplima89/SRE_Agent_Starter_Pack.git
	Set-Location SRE_Agent_Starter_Pack
	```

	If already working in a clone, start from its repository root. Git changes
	only local files; cloning needs repository read permission and no Azure role.
3. Read [Azure basics](docs/02-azure-basics-for-beginners.md),
	[prerequisites](docs/01-prerequisites.md), and
	[security](docs/04-security-and-governance.md).
4. Review [config/dev.json](config/dev.json) using
	[configuration guidance](docs/configuration.md). Fictional owner labels need
	replacement; cloud IDs, telemetry, region, model, and retention are unset.
	Never add credentials. A passing example is intentionally incomplete.
5. Run the offline checks from the repository root:

	```powershell
	./scripts/powershell/Test-Configuration.ps1 -ConfigPath ./config/dev.json
	./tests/unit/Test-Configuration.Tests.ps1
	./scripts/powershell/Test-Repository.ps1
	```

	Expected: configuration `PASS`, 21 unit checks, and repository `PASS`.
	The repository checker regression is fixed; it is still a limited heuristic
	checker, not a replacement for a dedicated secret scanner or runtime tests.
	Deployment readiness is `NOT CHECKED`. These commands require no Azure roles,
	create no cloud resources, and run no destructive tests. Tests use and remove
	one temporary local JSON file. Invalid settings throw and fail the command.
6. Record your workload owner, approved scope, evidence sources, and cost/data
	residency decisions. Review the deployment blockers before installing tools
	or granting roles for a future deployment.

Common error: running in Windows PowerShell 5.1. Open `pwsh`, then rerun.
Rollback: revert only your local configuration edits using your editor; no Azure
cleanup is needed. Cloning and offline checks have no Azure service charges.

## Production Adoption

1. Resolve the [contract gates](docs/phase-1-discovery.md#blocking-product-contract-issues)
	with pinned official templates and scoped disposable-environment evidence.
2. Approve identity, connectors, data handling, network access, retention,
	owners, incident routing, and cost before deployment.
3. Build/test Bicep and parity scripts with verified role definitions and exact
	solution ownership inventory. No default subscription Owner grants.
4. Require GitHub OIDC, separate environments, protected production reviewers,
	reviewed what-if, and security/rollback evidence before a production job.
5. Validate denied actions and OBO behavior, not just resource existence. Capture
	investigation evidence and audit access before enabling any schedule/alert.
6. Establish operational metric baselines. No improvement is guaranteed by
	deployment. Any future autonomy requires a separate allowlist, rollback,
	post-action verification, and workload-owner approval.

## Documentation

| Guide | Purpose |
| --- | --- |
| [Phase 1 discovery](docs/phase-1-discovery.md) | Verified sources, limitations, target tree, complete implementation plan. |
| [Solution overview](docs/00-solution-overview.md) | Adoption boundaries and maturity path. |
| [Prerequisites](docs/01-prerequisites.md) | Tools, OS choices, permissions, eligibility. |
| [Azure basics](docs/02-azure-basics-for-beginners.md) | Identity, resources, telemetry, and SRE terminology. |
| [Architecture](docs/03-architecture.md) | Components, data boundaries, Mermaid diagram. |
| [Security and governance](docs/04-security-and-governance.md) | Roles, approvals, OBO, privacy, and controls. |
| [Configuration](docs/configuration.md) | Field definitions and validation boundaries. |
| [Portal deployment](docs/portal-deployment.md) | Primary beginner route, parameter inputs, permissions, release checks, and lab limitations. |
| [Naming and tags](docs/naming-and-tags.md) | Product constraints versus kit conventions. |
| [Decision log](docs/decision-log.md) | Reasons for conservative design choices. |
| [Glossary](docs/glossary.md) | Plain-language reference. |
| [Release readiness](docs/release-readiness.md) | Audit, corrections, checks, and remaining work. |
| [Contract verification](docs/contract-verification.md) | Pinned source findings, compiled Bicep baseline, local IaC tests, and live gates. |

## Support and Contributions

This community starter is not an official Microsoft product or support channel.
Product source of truth: [Microsoft Learn](https://learn.microsoft.com/en-us/azure/sre-agent/overview)
and [microsoft/sre-agent](https://github.com/microsoft/sre-agent).
See [security reporting](SECURITY.md) before sharing logs or configuration.
Changes to safety behavior require regression tests and documented approval.