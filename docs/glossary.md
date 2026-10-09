# Glossary

Status: Phase 2 learning reference. Terms explain the proposed starter; they
are not API payloads, role assignments, or proof of a tested deployment.
Use [Azure basics](02-azure-basics-for-beginners.md) for exercises and
[security and governance](04-security-and-governance.md) for permissions.

## Azure and Identity

| Term | Meaning | Why it matters here |
| --- | --- | --- |
| Azure | Microsoft's cloud platform | Services, identities, and billing must be scoped explicitly |
| Tenant / Microsoft Entra ID | Identity directory for users, groups, and applications | Confirm the directory ID before selecting a subscription |
| Subscription | Billing and management boundary | Not the default scope for agent permissions |
| Management group | Container above subscriptions for governance | Permissions can be inherited into the workload |
| Resource group (RG) | Management container for Azure resources | Separate agent infrastructure from customer workload lifecycle |
| Resource ID | Full ARM path identifying subscription, group, provider, type, and name | Names/tags alone are not sufficient for evidence or safe cleanup |
| Region / home region | Geographic resource placement | Agent region does not prove inference residency; moving agent requires recreation |
| Resource provider | Namespace implementing resource types, such as Microsoft.App | Registration is a subscription write, handled later by platform admin |
| ARM / control plane | Azure Resource Manager resource deployment/configuration surface | SRE Agent base resource is Microsoft.App/agents; configuration contract conflicts remain |
| Data plane | Service-specific operations on data and agent behavior | Azure Contributor does not replace SRE Agent data actions |
| Principal / principal ID | Security identity and its directory object identifier | Distinguish identity object IDs from application IDs and resource IDs |
| RBAC | Role-based access control: principal, role, scope | Effective access includes inherited and group-based grants |
| Role definition | Allowed/excluded management actions and data actions | Inspect actual definitions, not only friendly names |
| Role assignment | Binding of a role to a principal at a scope | Exact assignment ID and ownership required for later removal |
| Scope | Boundary at which authorization applies | A narrow Reader grant cannot cancel a broad inherited write grant |
| Managed identity | Azure-managed application identity credentials | Removes credential handling for supported flows, not permission review |
| UAMI | User-assigned managed identity | Agent workload access and documented connector authentication; inspect all grants |
| SAMI | System-assigned managed identity | Agent infrastructure identity tied to resource lifecycle; not the workload principal |
| OBO | On-behalf-of authorization using a user's permissions | SRE Administrator with work/school account can authorize; Stage 0/1 rejects writes |
| PIM / just-in-time access | Privileged Identity Management / time-bound activation | Optional governance mechanism; licensing and availability not assumed |
| OIDC / federation | Token-based trust between identity systems | Future CI identity design; data-plane OIDC compatibility remains unverified |

## SRE Agent and Evidence

| Term | Meaning | Why it matters here |
| --- | --- | --- |
| SRE | Site reliability engineering | Investigate evidence, manage risk, preserve incident ownership |
| Azure SRE Agent | Azure service for AI-assisted investigation and operations | Product capabilities require scoped access, governance, and verification |
| Agent resource | Azure Microsoft.App/agents instance | A deployed resource alone proves neither telemetry nor safety |
| Custom agent | Authored specialization of agent behavior | Human Author role can create behavior but cannot approve actions |
| Skill | Reusable procedural knowledge/behavior | Exact implementation/schema not supplied by this phase |
| Knowledge | Operational context supplied to the agent | May contain secrets/customer data; review before upload |
| Thread | Investigation conversation/operational record | Can contain sensitive results; not by itself a complete audit record |
| Response plan | Incident-triggered behavior configuration | Product defaults Autonomous; kit requires explicit Review and disabled start |
| Scheduled task | Recurring automated work | Same Autonomous default risk; disabling must be verified in future contract |
| Review | Approval workflow for applicable actions | Not a universal external-write gate or strict no-change mode |
| Autonomous | Applicable actions proceed without waiting for approval | Not allowed in the foundation policy |
| ReadOnly | Value present in the versioned base ARM mode schema | Do not infer a task/plan enum or end-to-end safety guarantee |
| Stage 0 / Stage 1 | Kit maturity labels: observe / recommend | Not Azure enums; neither allows target-resource/external writes |
| Tool | Operation the agent can invoke | Inspect effective runtime tool name, arguments, scope, and privileges |
| Tool policy | Global/custom-agent/thread access decisions | Allow beats Ask; user-hook Allow can override global Deny |
| Hook | Custom contextual decision/behavior around operations | Schema/failure behavior pending; no generic Allow hook in baseline |
| Connector | Integration exposing data or operations | Auth and tool permissions must both restrict external writes |
| MCP | Model Context Protocol for tool/data integrations | Optional interface, not a guarantee of trustworthy or read-only operations |
| Prompt injection | Untrusted input trying to redirect agent behavior | Treat logs/code/knowledge as untrusted; prompts are not authorization controls |
| Telemetry | Metrics, logs, and traces | Existing source must actually contain recent approved workload evidence |
| Metric | Numeric time-series signal | Missing data is not evidence of good health |
| Log | Event record queried from a data source | May expose personal/customer information and query cost |
| Trace | Linked operations across service requests | Sampling and missing instrumentation limit conclusions |
| Azure Monitor | Azure monitoring platform | Alert lifecycle writes are not accepted Stage 0 observations |
| Log Analytics workspace | Log store/query boundary | Shared workspace can expose unrelated workloads; review data access |
| Application Insights | Application observability service | Connection string is sensitive and must not be checked into kit config |
| Incident | Service-impact investigation/response record | Customer incident process remains authoritative |
| Hypothesis | Proposed explanation tested against evidence | Record observations separately from model inference |
| Negative test | Deliberate forbidden operation with expected rejection | Needed to prove no-write and scope enforcement, not only successful reads |
| Effective permissions | Combined current privilege across roles/scopes/groups | Includes portal side effects and OBO-capable humans |

## Delivery, Costs, and Status

| Term | Meaning | Why it matters here |
| --- | --- | --- |
| IaC | Infrastructure as code | Future phase only, blocked on contract validation |
| Bicep | Declarative Azure resource language | Intended primary backend; no kit implementation yet |
| Terraform / AzAPI | IaC tool / provider using Azure ARM contracts | Optional verified parity path; no fictional native SRE resource |
| az / Azure CLI | Command-line Azure management tool | Upstream CLI 2.x; actual future compatibility must be tested |
| azd | Azure Developer CLI | Optional future wrapper, not required or implemented here |
| JSON config | Kit-owned environment settings format | Future dev/test/prod files are not SRE Agent upload payloads |
| Preview API | API explicitly using a preview contract | 2025-05-01-preview examples cannot be transplanted into newer ARM blindly |
| Stable channel | Resource upgradeChannel value | Does not certify all configuration APIs or connector schemas |
| GA | General availability product milestone | Do not call the entire product preview because an API example is preview |
| Release gate | Evidence required before implementation/release | Version, no-write, approval, and configuration gates are still open |
| REVIEWED | A document or supplied record was inspected | Not a passed live test |
| NOT CHECKED | A check has not run or lacks evidence | All live Azure checks in this phase |
| BLOCKED | A dependency or safety gate prevents proceeding | Do not invent a contract to change the status |
| Budget | Spending notification/control configuration | Not a guaranteed hard cap; future creation is a separate write |
| Fixed/variable cost | Always-on charges / usage-sensitive charges | Stopping agent does not eliminate always-on cost |
| Residency | Rules about where data is stored/processed | Review inference and connector destinations separately from home region |
| Rollback | Approved restoration of prior state after a change | Agent deletion does not undo workload/external changes |
| Ownership inventory | Verified created-resource and exact-assignment record | Needed for cleanup; mutable tags/prefixes alone are unsafe |

## How to Use This Reference

1. **Mandatory for a review:** identify whether an unfamiliar label is a product
   term, kit policy, or future artifact before making a decision.
2. Find the linked guide and source for the term. Evidence: source/date and the
   specific permission, scope, or behavior being claimed.
3. If product pages disagree, record the conflict in the
   [decision log](decision-log.md); do not resolve it by guessing an API.

**Permissions:** none for offline reading. **Resources changed:** documents
only if an approved terminology correction is made. **Common error:** confusing
Review with read-only RBAC or Stable channel with a verified API. **Rollback:**
withdraw the mistaken interpretation before execution. **Cost/privacy:** no
cloud charges from reading; use sanitized examples, not real secrets or logs.
Optional feature mentions remain design-only:
**Optional placeholder requiring validation against current Azure SRE Agent documentation.**

## Official Sources

Definitions follow the [Phase 1 source ledger](phase-1-discovery.md),
[overview](https://learn.microsoft.com/en-us/azure/sre-agent/overview),
[user roles](https://learn.microsoft.com/en-us/azure/sre-agent/user-roles),
[permissions](https://learn.microsoft.com/en-us/azure/sre-agent/permissions),
[run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes),
[tool policies](https://learn.microsoft.com/en-us/azure/sre-agent/tool-access-policies),
[ARM reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents),
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing), and
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy).