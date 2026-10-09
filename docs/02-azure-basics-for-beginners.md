# Azure Basics for Beginners

Status: learning and inspection only. No cloud changes are required. Read the
[overview](00-solution-overview.md) and keep the [glossary](glossary.md) nearby.
The [Phase 1 record](phase-1-discovery.md) distinguishes documented product
behavior from kit policy and unverified implementation.

## Your First Mental Model

Think of Azure as resources inside an ownership and permission hierarchy, not
one shared administrator account.

| Concept | Plain-language meaning | Starter example / trap |
| --- | --- | --- |
| Microsoft Entra tenant | Identity directory for people and applications | A subscription can appear in the wrong selected directory; verify IDs |
| Subscription | Billing and management boundary | It is not your login identity and is not the desired default RBAC scope |
| Resource group (RG) | Management container for related Azure resources | One approved workload RG, separate future agent RG; deleting a group is destructive |
| Resource | A deployed service instance with a full ID | A workspace, web app, or future SRE Agent; names alone do not identify scope |
| Region | Resource's home geography | Agent region does not guarantee model inference/data residency |
| ARM | Azure Resource Manager, the control plane | Creates/configures resources; does not prove application data access |
| Data plane | Service-specific operations on data or agent interactions | Log queries, repository reads, chat, and approvals have separate authorization |
| RBAC | Role-based access control | Permission = principal + role + scope, including inherited grants |
| Managed identity | Azure-managed application identity | UAMI for agent workload access; SAMI for agent infrastructure |
| Telemetry | Metrics, logs, and traces describing service behavior | Existing data can contain personal data, secrets, and query costs |
| Connector | Integration to another data/tool system | A read-looking workflow can expose issue/PR/email write tools |

An illustrative resource ID has this shape, not a runnable command:

```text
/subscriptions/<subscription-id>/resourceGroups/<group>/providers/<namespace>/<type>/<name>
```

Always carry the full resource ID in evidence. A resource called `payments`
can exist in different subscriptions; a tag or friendly name is not a security
boundary. Management-group and subscription assignments can be inherited by
every resource below them.

## Exercise 1: Confirm Where You Are

**Mandatory before a future lab; optional read-only inspection now.** If you
are learning offline, ask an approved owner for redacted screenshots instead.

1. Open the Azure portal and inspect the currently selected directory. Compare
   the tenant ID, not only the organization name, to your approved record.
2. Inspect the subscription name and ID. Have the platform owner confirm that
   it is the non-production subscription chosen for the lab.
3. Open the existing workload RG Overview. Record its full resource ID, owner,
   region information, and whether it contains shared services.
4. Stop if any ID differs or the scope is unclear. Do not create a group or
   request wider permissions to continue the exercise.

**Permissions:** existing Reader visibility on the relevant scope, or evidence
provided by its owner. **Resources changed:** none. **Expected evidence:** a
dated tenant/subscription/RG mapping approved by the workload owner.
**Common errors:** wrong directory, similarly named subscription, or insufficient
read access. **Rollback:** none in Azure; correct the record or switch portal
context. **Cost/privacy:** browsing is not provisioning; screenshots can expose
IDs, billing information, and internal names, so store them privately.

## Exercise 2: Understand an Identity and Role

A principal is a person, group, application, or managed identity. A role is a
bundle of allowed actions. A scope is where those actions apply. Multiple
assignments combine; a narrow Reader grant does not cancel an inherited write
grant. A deny assignment is distinct from an SRE tool-policy Deny.

1. With an IAM reviewer, select one existing read assignment in the workload
   group's Access control (IAM) view, or use a redacted export from that reviewer.
2. Record principal, exact role name, assignment ID, scope, and whether inherited.
   Do not click Add role assignment or change membership.
3. Ask which control-plane actions and data actions the role includes. Reader
   resource visibility is not universal access to logs, secrets, or repository
   contents. Ask about telemetry table/resource permissions separately.
4. Compare with the persona matrix in
   [security and governance](04-security-and-governance.md). Request a scoped
   review when there is a gap, not a general Contributor grant.

**Permissions:** IAM read visibility or owner-provided evidence. **Resources
changed:** none. **Expected evidence:** assignment and inherited-access record.
**Common errors:** assuming role display names imply no writes, or ignoring
group membership and subscription grants. **Rollback:** cancel a proposed grant;
never remove a user's existing unrelated role. **Cost/privacy:** IAM exports
reveal user identities; limit access and retention.

### The Two Agent Identities

- **SAMI (system-assigned managed identity):** tied to the agent's lifecycle;
  used for infrastructure in the documented creation flow. Do not treat it as
  the workload-access principal or add broad workload permissions to it.
- **UAMI (user-assigned managed identity):** separately represented identity;
  used for workload access and documented connector authentication. Its exact
  assignments and lifecycle must be inspected. Reusing a broadly privileged
  UAMI would import that privilege into the agent.

Azure manages identity credentials, but you still manage authorization.
Managed identity does not mean read-only, nor does it eliminate every external
connector secret. OBO (on-behalf-of) can temporarily use an SRE Agent
Administrator's Azure permissions when UAMI access is missing. Reject write
OBO requests in Stage 0/1, even in a non-production lab.

## Exercise 3: Read a Health Signal

**Mandatory evidence for future investigation; no new instrumentation now.**
Metrics are numeric time series, logs are records you query, and traces relate
operations across services. An alert is a configured signal, not proof of cause.

1. Ask the workload owner which one existing telemetry source is approved.
2. Ask the data owner for a small, read-only time window with a known recent
   request or event. Inspect timestamps, resource labels, and query boundaries.
3. Record whether data is current, delayed, sampled, or missing. A zero-error
   chart can mean no data rather than a healthy service.
4. Write a bounded hypothesis, such as "errors increased after deployment X,"
   and the evidence that would disprove it. Do not restart anything to test it.

**Permissions:** approved metrics/log read access; the owner may supply results
instead. **Resources changed:** none; no diagnostic settings or alert changes.
**Expected evidence:** source ID, time range, query or chart context, redacted
result, and limitations. **Common errors:** wrong workspace/time zone, ingestion
delay, missing table permission, or absent instrumentation. **Rollback:** stop
the query and correct the record, not the workload. **Cost/privacy:** queries
may be metered under the chosen service/tier; logs/traces can include customer
payloads. Avoid bulk export and unrestricted time ranges.

## Modes, Human Roles, and Writes

These are separate controls, not interchangeable labels:

| Control | Question it answers | Important limitation |
| --- | --- | --- |
| Azure RBAC on the UAMI | What Azure resources can the agent access? | Portal Reader onboarding documents subscription Monitoring Contributor writes |
| SRE Agent human roles | Who can view, chat, author, approve, administer? | Azure Owner/Contributor does not replace SRE data actions |
| Review/Autonomous run modes | Will an action ask for approval? | Tasks/plans default Autonomous; Review does not gate all external writes |
| Tool policies and hooks | Is a tool allowed, asked, or denied? | Allow beats Ask; user-defined hook Allow can override global Deny |
| Connector permission | What can an integration do externally? | A repository reader is not automatically a read-only connector |

Only SRE Agent Administrators approve actions and authorize OBO. Author alone
cannot chat or upload knowledge in the portal. Standard User can investigate
but also manage scheduled tasks and add repository connectors; it is not a
purely read-only role. The required no-change baseline must be proven with
multiple controls, not inferred from the word Review.

The ARM reference lists `ReadOnly`, `Review`, and `Autonomous` for
`actionConfiguration.mode`. The run-mode guidance describes per-plan/per-task
Review and Autonomous, with an agent fallback. These are not a verified
end-to-end configuration recipe. Do not infer a task `ReadOnly` enum or send
the kit's Stage 0 label to Azure.

## Paying for and Undoing Changes

For a future approved operation, always ask: which resources change, who has
permission, what evidence proves success, how could it fail, and what is the
rollback? Deleting an agent does not undo changes it already made to a workload
or external system. Restoring a setting requires its previous value; deleting
an entire RG is not a reasonable substitute.

Preparation here changes documents only. Future agent billing has fixed and
variable components, and stopping the agent does not eliminate always-on cost.
Telemetry retention, new collection, models, optional integrations, and network
resources may add charges. A budget is an alert, not an automatic spending cap.
No subscription Owner grant is required merely to learn or prepare.

## Official Sources

Use the [Phase 1 source ledger](phase-1-discovery.md),
[product overview](https://learn.microsoft.com/en-us/azure/sre-agent/overview),
[creation and identity flow](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up),
[human roles](https://learn.microsoft.com/en-us/azure/sre-agent/user-roles),
[agent permissions](https://learn.microsoft.com/en-us/azure/sre-agent/permissions),
[run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes),
[versioned ARM reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-01-01/agents),
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing), and
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy).
For general concepts, see [Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
and [managed identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview).