# Naming and Tags

Status: Phase 2 conventions, not created resources or an Azure policy deployment.
Use the [prerequisite scope record](01-prerequisites.md) and
[decision log](decision-log.md). Evidence baseline:
[Phase 1 discovery](phase-1-discovery.md), 2026-10-09.

## Product Constraint Versus Kit Convention

The versioned ARM reference specifies this **agent resource name** pattern:

```text
^[A-Za-z]([-A-Za-z0-9]{0,30}[A-Za-z0-9])$
```

It allows **2-32 characters**, starts with a letter, ends with an alphanumeric
character, and permits letters, digits, and hyphens between. It does not
establish naming rules for RGs, identities, workspaces, connectors, model names,
or global endpoint uniqueness. Inspect each resource type's rules later.

The following lower-case prefixes, tokens, and patterns are **kit-owned
conventions**, not Azure API requirements or proof of availability:

| Token | Convention | Example | Evidence / validation |
| --- | --- | --- | --- |
| `org` | Short organization code; letters/digits, beginning with a letter | `contoso` | Platform naming owner approves; no customer-identifying secret |
| `workload` | Short workload code using letters/digits | `pay` | Workload owner maps to inventory; not a data-classification label |
| `env` | `dev`, `test`, or `prod` | `dev` | Kit environment selector; prod name/config does not authorize production |
| `regioncode` | Approved abbreviation, not a location input | `eus2` | Map explicitly to candidate `eastus2`; actual availability NOT CHECKED |
| `nn` | Two-digit differentiator | `01` | Check for collisions within verified resource scope |

By restricting individual tokens to letters/digits, the kit puts hyphens only
at separators. That is stricter than the product pattern; do not describe it
as an ARM restriction. Never derive a deployment region solely from a suffix.

## Proposed Resource Names

| Object | Kit-owned pattern | Example | Ownership / qualification |
| --- | --- | --- | --- |
| Agent | `sre-{org}-{workload}-{env}-{regioncode}-{nn}` | `sre-contoso-pay-dev-eus2-01` | Example length 27, valid ARM agent syntax; eligibility/availability not checked |
| Dedicated future agent RG | `rg-{org}-{workload}-sre-{env}-{regioncode}` | `rg-contoso-pay-sre-dev-eus2` | Future platform-owned provisioning; check RG rules separately |
| Workload-access UAMI | `id-{org}-{workload}-sre-{env}-{nn}` | `id-contoso-pay-sre-dev-01` | Proposed dedicated identity; exact product creation/attachment behavior pending |
| Separate future agent telemetry | `appi-{org}-{workload}-sre-{env}-{nn}` | `appi-contoso-pay-sre-dev-01` | Design-only; resource type/lifecycle and naming rules to verify |
| Existing workload/telemetry/repository | Keep customer names and IDs | Owner's existing inventory | Do not rename, retag, move, or claim ownership to fit the kit |
| SAMI | No independent resource-name pattern | Identity tied to future agent | Record principal ID separately; do not invent a standalone SAMI resource |

Optional additional connector/network/incident resources are not named or
created by this foundation:
**Optional placeholder requiring validation against current Azure SRE Agent documentation.**

### Length and Syntax Examples

| Candidate agent name | Product syntax result | Reason |
| --- | --- | --- |
| `ab` | Valid syntax | Minimum length 2, starts letter, ends alphanumeric |
| `a1` | Valid syntax | Digit at the end allowed |
| `sre-contoso-pay-dev-eus2-01` | Valid syntax | 27 characters and only allowed characters |
| `a` | Invalid | Single character; minimum is 2 |
| `1agent` | Invalid | Starts with a digit |
| `agent-` | Invalid | Ends with hyphen |
| `agent_name` | Invalid | Underscore not allowed for agent name |
| `agent.prod` | Invalid | Dot not allowed for agent name |
| `sre-verylongorganization-pay-dev-eus2-01` | Invalid | Exceeds 32 characters |

Valid syntax is not a uniqueness, endpoint, policy, or deployment check. Long
organization/workload tokens can overflow the full pattern even when each token
is valid. Agree on short codes; do not silently truncate, which can collide.

## Tag Proposal

These are **kit governance tags**, not SRE Agent schema fields. Proposed
mandatory tags apply only to future kit-owned resources that support tags,
subject to customer policy. Tags are generally management metadata, not a
place for credentials, personal data, or raw incident content. Do not assume
tags propagate from an RG to its resources.

| Tag | Mandatory/optional | Example value | Purpose / review owner |
| --- | --- | --- | --- |
| `ManagedBy` | Mandatory | `sre-agent-starter` | Describes management intent, not proof of ownership |
| `SolutionId` | Mandatory | `contoso-pay-sre-dev-01` | Stable kit deployment correlation; not unique by platform guarantee |
| `Environment` | Mandatory | `dev` | Environment reporting; must agree with approved scope |
| `Workload` | Mandatory | `pay` | Workload attribution; workload owner validates |
| `OwnerTeam` | Mandatory | `platform-sre` | Accountable team alias, not personal email |
| `CostCenter` | Mandatory | `cc042` | Approved non-sensitive billing allocation |
| `DataClassification` | Mandatory | `internal` | Customer classification vocabulary; not enforcement or residency proof |
| `Lifecycle` | Mandatory | `lab` | Indicates intended lifecycle; lab does not permit unsafe cleanup |
| `ReviewBy` | Mandatory for future lab | `2026-11-09` | Example review date; no automatic expiry/deletion implied |
| `ChangeReference` | Optional | `chg-example-001` | Approved change correlation; omit confidential descriptions |
| `Repository` | Optional | `sre-starter` | Non-sensitive repository alias, not token-bearing URL |

Tags do not grant RBAC, enforce a budget, constrain inference processing, or
prove the resource was created by the kit. A copied `SolutionId` must never
make a shared resource eligible for deletion. Apply no tags to existing
customer resources without separate owner approval.

## Numbered Naming and Tag Review

1. **Mandatory:** select approved organization/workload codes and the real
   environment. Evidence: naming-owner approval and scope record. Permissions:
   local review only. Resources changed: proposed record only.
2. **Mandatory:** compose the whole agent name and verify the ARM regex plus
   2-32 length. Evidence: explicit length/syntax result. A future validator
   must test negative cases above; it is not implemented in this phase.
3. **Mandatory:** map the region code to a full candidate Azure location and
   check naming collisions through authorized owners. Evidence: mapping and
   later subscription/creation-picker availability, currently NOT CHECKED.
   Permissions: read visibility for a future check, no resource creation.
4. **Mandatory:** select non-sensitive tags with cost/security owners; document
   any customer-policy conflict. Evidence: exact key/value proposal and reviewer.
   Resources changed now: none; saving tags in Azure is a future write.
5. **Mandatory:** record ownership separately using future actual resource and
   assignment IDs. Evidence: created-resource inventory and shared-resource
   exclusion. Tags and prefixes alone never authorize cleanup.
6. **Optional:** propose other resource names only after their resource-type
   constraints are verified. Evidence: official type-specific naming source;
   keep optional SRE configurations labeled unverified.

## Errors, Recovery, Costs, and Privacy

| Problem | Safe correction | Rollback |
| --- | --- | --- |
| Name too long/invalid | Shorten approved tokens explicitly; retest entire name | Revise proposed document; do not rename existing resources |
| Collision or unknown uniqueness boundary | Verify resource/endpoint constraints with platform owner | Choose a new approved differentiator before a future deployment |
| Tag blocked by customer policy | Ask policy owner; document compliant values | Withdraw proposal; do not weaken Azure Policy |
| Sensitive tag value | Replace with team alias/non-sensitive code | Future authorized removal does not erase logs/history; follow exposure process |
| Existing resource carries kit-looking tags | Treat ownership as unproven | No deletion; reconcile IDs against verified inventory |
| Region code mistaken for residency control | Review actual location and provider data flows | Withhold deployment; future region move requires agent recreation |

Documentation proposals create no Azure charges. Future applying tags needs
resource-write permission, is not a read-only operation, and must not be done
by Stage 0/1 workload investigation. Naming does not reserve a resource, stop
billing, or enforce a spending cap. Keep customer identities and secrets out
of management metadata. A future rollback removes/restores only specifically
approved kit changes; preserve existing customer names, tags, and resources.

## Official Sources

See [Phase 1 verified resource contract](phase-1-discovery.md),
[ARM agent name/schema reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents),
[creation](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up),
[regions](https://learn.microsoft.com/en-us/azure/sre-agent/supported-regions),
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy), and
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing).
For other Azure resources, consult [resource naming rules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules)
and [tag guidance](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources).