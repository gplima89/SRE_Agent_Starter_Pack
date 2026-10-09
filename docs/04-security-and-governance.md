# Security and Governance

Status: required design review, not a certified enforcement configuration.
Evidence baseline: 2026-10-09, [Phase 1 discovery](phase-1-discovery.md).
Phase 3+ remains blocked pending contract and effective-permission validation.
No Azure role assignments or policy changes are authorized by this document.

## No-Change Foundation

Stage 0 observes; Stage 1 recommends. Both forbid writes to workload resources
and external systems. Internal agent threads/usage records are distinct from
target-resource changes. Read access can still expose confidential data or
incur query/agent costs. Use one non-production workload, one approved repository,
and one telemetry source, not subscription-wide discovery by convenience.

Mandatory policy for a future lab:

- Explicitly select Review on every response plan and scheduled task, and start
  them disabled. Tasks and plans default to Autonomous; the agent's Review
  fallback is not enough. Verify effective settings after each configuration.
- Do not authorize OBO writes in Stage 0/1. A low-privilege UAMI is not a
  complete protection when an Administrator has broader Azure rights.
- Restrict Azure and external integration permissions; no broad write tools,
  generic Allow hooks, or wildcard approvals. Verify runtime tool identities
  and coverage rather than relying on a prompt saying "read only."
- Separate investigators, authors, governance administrators, and IAM operators.
  Do not grant subscription Owner automatically, including to the deployer.
- Keep changes, role grants, provider registration, and live testing behind
  separately recorded tenant, scope, cost, privacy, and change approvals.

## Read-Only Persona and Role Matrix

This is a **proposed least-privilege matrix**, not a list of roles to assign now.
Inspect actual role definitions (Actions, NotActions, DataActions, NotDataActions),
effective assignments, group membership, and inheritance before implementation.
Built-in role names do not prove the exact minimum for a deployment contract.
An agent data role and Azure resource RBAC solve different problems.

| Persona / principal | Scope | Role | Why | When / temporary or permanent | Risk | Safer alternative |
| --- | --- | --- | --- | --- | --- | --- |
| Auditor/stakeholder | Exact agent resource | SRE Agent Reader | View threads, logs, incidents without chat or changes | Future oversight; permanent only with periodic review | Sensitive investigation data remains visible | Time-limited access or redacted approved reports |
| Investigator/on-call | Exact agent resource | SRE Agent Standard User | Chat and run diagnostics; cannot approve actions or authorize OBO | Future approved investigation; time-bound group membership preferred | Can also manage tasks, upload knowledge, add repository connectors; not a pure read-only role | Reader plus human-provided analysis if these capabilities cannot be constrained; keep live investigation blocked pending tested controls |
| Response-plan/custom-agent author | Exact agent resource | SRE Agent Author | Author behavior and plans without approval power | Future reviewed authoring window; temporary | Can create unsafe behavior; Author alone cannot chat/upload knowledge/add repo via portal | Reviewed proposal only; do not combine with Administrator |
| Author needing portal chat/knowledge/repository access | Exact agent resource | Standard User plus Author | Supplies data actions Author alone lacks | Exception-only, temporary, explicitly approved | Combined role widens authoring and integration/task surface | Split author and investigator duties; reviewer transfers approved content later |
| Governance/approval administrator | Exact agent resource | SRE Agent Administrator | Settings, connectors, hooks, approvals; governance only in Stage 0/1 | Temporary administrative window; emergency access reviewed | Can approve actions, authorize OBO, delete, and install hook Allow overrides | No standing access; independent change review and minimal Azure permissions for the same person |
| UAMI: resource inventory | One approved workload RG, narrower if feasible | Reader | View resource configuration | Future operating access; permanent only while approved | Inherited Contributor/Owner can invalidate no-write intent; configuration may expose sensitive values | Individual resource scope and reviewed data minimization |
| UAMI: metrics/monitoring | Approved monitored resources or workload RG | Monitoring Reader | Read monitoring evidence where required | Future only after demonstrated need; reviewed ongoing grant | Additional data visibility; does not negate other grants | Existing bounded owner-provided metrics if sufficient |
| UAMI: log queries | One approved existing workspace/source boundary | Log Analytics Reader, subject to resource/table access review | Query approved workload logs | Future only after demonstrated need; reviewed ongoing grant | Workspace may contain other workloads/customer data; inspect all effective actions | Narrower resource-context/table-access design verified by data owner, or redacted bounded results |
| SAMI: agent infrastructure | Exact required infrastructure resources, contract pending | No workload role by default; exact infrastructure role unresolved | Operate agent infrastructure, not investigate workloads | Future creation/runtime only when verified | Guessed Contributor scope could leak workload privilege | Keep contract gate open rather than invent a role/grant |
| Repository/data owner | Exact repository/source | Service-specific read permission, contract pending | Authorize minimum evidence access | Future connector setup; expiry/review per service | Tokens/tools may include writes or unrelated repos | Owner-provided sanitized read evidence until contract validated |
| Future deployment operator | Dedicated precreated agent RG and exact identity attachment scope | Scoped Contributor and, only if needed, Managed Identity Operator; exact requirements to verify | Deploy approved infrastructure and attach only approved UAMI | Temporary deployment window; not assigned in Phase 2 | Control-plane write access; can deploy other resources in scope; does not grant SRE data actions | Constrained custom deployment role after verified operation inventory; platform-operated deployment |
| IAM assignment operator | Exact resources/RGs requiring approved grants | Role Based Access Control Administrator, constrained if supported and verified | Assign/remove separately approved exact roles | Temporary approved assignment window | Role-assignment authority can elevate principals beyond intended access | Platform IAM team performs exact grants with independent review; no deployer assignment authority |
| Platform admin | Subscription only for authorized provider registration; RG creation separately approved | Organization's existing scoped admin role; no new Owner request | Register required provider/precreate dedicated RG when later authorized | One-time future platform task | Subscription actions have wide impact; registration is a write | Existing central platform workflow; narrower verified registration permission |
| Portal-onboarded UAMI side effect | Subscription | Monitoring Contributor (documented onboarding grant; **not accepted baseline**) | Product flow manages alert lifecycle/monitoring settings | Neither permanent nor temporary accepted for strict Stage 0 | Acknowledge/close alerts and monitoring writes beyond workload RG | Do not complete onboarding as compliant; verify supported no-write alternative before release |

Candidate deployment/IAM roles are privileged preparation requirements, not
agent runtime grants. Use PIM/just-in-time access if available and approved;
licensing and tenant setup are not assumed. An Administrator human role does
not itself grant Azure Contributor, but broader Azure rights on that same
person can become available through OBO. Account and emergency-access design
must be reviewed together.

The documented creation flow automatically gives the creator SRE Agent
Administrator. Inspect and replace/remove this exact assignment through the
approved IAM process when no longer needed. Do not confuse that product
behavior with a kit grant of subscription Owner. Azure Owner/Contributor
does not substitute for SRE Agent data-plane roles.

## Control Precedence: Why Review Is Not Enough

The official tool policy guidance describes this order:

1. **Hooks:** a user-defined hook returning Allow skips controls below it,
   including a global Deny. Hook Deny blocks; Hook Ask asks. Only Administrators
   create hooks. Audit logging does not make an override safe.
2. **Tool access policies:** absent a hook decision, global Deny blocks first;
   Allow at any permitted scope overrides Ask and executes immediately. Only
   global scope has Deny/Ask; custom-agent/thread policies add Allow.
3. **Default approval controls:** connector Ask / RequiresApproval can request
   approval when no higher-priority decision applies.
4. **Run mode:** Review pauses where approval applies; Autonomous can
   auto-approve. Unmatched tools can execute without an approval requirement.

Review shows approval for Azure infrastructure operations, not every external
write. Emails, Teams posts, issue/PR changes, and incident actions need their
own verified tool/connector restrictions. A global Deny is not invulnerable
to user-hook Allow. Prompt instructions are not authorization controls.

Do not ship a hook or policy payload here. Hook fail-closed behavior, runtime
matching, connector write restrictions, and actual API schemas remain release
gates. Any proposed optional hook or integration must say:
**Optional placeholder requiring validation against current Azure SRE Agent documentation.**

## OBO and Onboarding Stop Conditions

OBO lets the agent temporarily use an SRE Agent Administrator's Azure permissions
when its UAMI lacks access. The documented flow requires a work/school Entra
account; a personal Microsoft account cannot authorize it. Authorization not
being retained does not undo a write already performed.

If an OBO write request appears in Stage 0/1: deny, stop the run, preserve the
request/resource/tool evidence, and escalate. Do not approve "just once" to
finish diagnostics. Even an OBO read request requires scope and data-owner
review; it must not expand the investigation outside the approved boundary.

The portal permissions guide documents Reader, Log Analytics Reader, and
Monitoring Reader at RG scope, plus Monitoring Contributor at **subscription**
scope. The Reader permission-level label therefore does not mean a strictly
read-only inventory. Its documented monitoring writes block strict Stage 0
baseline release. Neither silently accepting this role nor deleting it and
claiming the product will work is a verified solution. Supported operation
without the grant must be established in an authorized disposable lab first.

## Numbered Security Review

1. **Mandatory: approve scope and principals.** Record tenant, subscription,
   resource IDs, UAMI/SAMI responsibilities, human role combinations, owner, and
   expiry. Permission: authorized IAM visibility or owner-provided evidence.
   Changes: documents only. Evidence: reviewer-approved role matrix proposal.
2. **Mandatory: inspect effective access.** For a future lab capture exact
   role definitions/assignment IDs, inherited management-group/subscription
   roles, groups, eligible/active privilege, and telemetry data access. Compare
   before and after onboarding. Changes now: none; live inventory NOT CHECKED.
   Evidence: bounded redacted inventory and explanation for every grant.
3. **Mandatory: review execution paths.** Enumerate intended read tools, external
   tools, shell/code execution, plans/tasks, policies, hooks, and OBO. Changes:
   no configuration applied. Evidence: threat cases and runtime/schema questions.
4. **Mandatory: review information flows.** Classify logs/code/knowledge/prompts,
   restrict source scope/time ranges, choose permitted destinations/retention,
   and inspect model residency. Evidence: privacy/data-owner approval. Changes:
   no ingestion/export enabled in this phase.
5. **Mandatory: define negative tests and audit.** Use the table below as future
   acceptance, not runnable scripts. Evidence: independent expected outcomes,
   exact denied operation/resource, audit access, and no target-state change.
6. **Mandatory: decide readiness.** Require all four Phase 1 gates closed, dated
   reviewers and separate cost/change approval before Phase 3 release. Evidence:
   tested contract mapping and no-write proof. Current outcome: BLOCKED; live
   tests NOT CHECKED. Never substitute a successful deployment for proof.

Permissions for this review are organizational approval and read visibility,
not subscription Owner. Optional connector review requires its system owner.
Common errors are hidden inherited grants, missing data actions, an unreviewed
creator Admin assignment, mismatched runtime tool patterns, and treating a 403
as a reason to add Contributor. Recovery is a scoped review, not elevation.

## Future Negative-Test Acceptance

Run only after schemas are verified, with explicit authorization in a
disposable lab. Use harmless canary resources and external test systems, never
customer production objects. All results are currently **NOT CHECKED**.

| Test | Expected outcome | Evidence required |
| --- | --- | --- |
| In-scope resource/telemetry read | Only approved data returned | Principal, exact scope, bounded source/time range, redacted result |
| Out-of-scope read | Denied; no expansion through OBO | Failure/audit evidence and no unrelated data returned |
| Azure write from chat/task/plan | Blocked in Stage 0/1 | Attempt and effective settings; unchanged target state |
| External email, issue/PR, incident or notification write | Blocked, not merely missing Review buttons | External permissions/tool inventory and unchanged canary state |
| Task/plan default regression | Missing explicit Review/disabled state rejected by future kit validation | Negative local config test and later effective-settings inspection |
| Allow plus Ask | Precedence understood; no baseline write path introduced | Runtime policies reviewed; unsafe Allow excluded |
| User-hook Allow plus global Deny | Demonstrates override risk only in separately authorized isolated test; override excluded from baseline | Audited hook/policy inventory, no generic Allow in accepted baseline |
| OBO write elevation | Refused; no successful elevation/write | Prompt/audit and unchanged canary state; human Azure rights reviewed |
| Hook failure/timeout or unknown connector tool | Safe behavior must be proven, not assumed | Verified failure semantics and blocked unsafe paths |
| Portal onboarding side effects | No accepted monitoring write grant in strict baseline | Before/after assignments including subscription scope; supported alternative demonstrated |

Policy tests and RBAC tests are both necessary: an operation failing because
the test user lacks access does not prove the policy would block a privileged
user. Run variants for relevant identities and roles; capture failures as well
as successes. Actual tool/schema coverage remains unresolved.

## Secrets, Audit, Costs, and Rollback

Never commit App Insights connection strings, incident keys, repository tokens,
bearer tokens, customer logs, or raw IAM/user exports. Future JSON config holds
non-secret settings or verified secret references only; no secret-reference
format is invented here. Minimize prompt/knowledge content and treat repository
text, incident text, and retrieved content as untrusted input. A document
instructing the model to ignore policy must not grant it permissions.

Privacy review covers inference that may leave the selected agent region,
external destinations, retention, access/deletion requirements, and model/provider
selection. Agent threads can contain sensitive results. Audit requirements:
who requested, what tool/scope was used, why it was allowed/denied, OBO/approval
actor, resulting state, and retention/access owner. Export and coverage must
be verified; a visible thread alone is not a compliance guarantee.

No resources change in this phase. Future reviews/tests may incur agent,
query, telemetry, identity-governance licensing, and external service costs.
Stopping the agent does not eliminate always-on cost. Budgets alert rather
than enforce a cap; the cost owner must define monitoring and escalation.

1. For a documentation mistake, withdraw the proposed decision and retain the
   reason; no cloud rollback is needed.
2. For a future unsafe run, deny the action, stop/disable relevant automation
   through supported verified controls, and preserve evidence. Stopping alone
   does not revoke roles, connector credentials, or reverse writes.
3. Have the authorized IAM/integration operator remove only exact approved
   solution-created grants/credentials after impact review. Do not remove
   shared grants by name or tags; do not promise individual onboarding-role
   removal behavior until verified against product documentation.
4. Restore any changed target setting using its independently recorded prior
   state and approved workload rollback. Deleting the agent is not rollback
   for external or workload changes. Revoke/rotate exposed credentials with
   their owner if exposure is suspected.

## Official Sources

[Phase 1 evidence and release gates](phase-1-discovery.md),
[user roles](https://learn.microsoft.com/en-us/azure/sre-agent/user-roles),
[agent permissions and onboarding](https://learn.microsoft.com/en-us/azure/sre-agent/permissions),
[run modes](https://learn.microsoft.com/en-us/azure/sre-agent/run-modes),
[tool policies and precedence](https://learn.microsoft.com/en-us/azure/sre-agent/tool-access-policies),
[creation](https://learn.microsoft.com/en-us/azure/sre-agent/create-and-set-up),
[privacy](https://learn.microsoft.com/en-us/azure/sre-agent/data-privacy), and
[pricing](https://learn.microsoft.com/en-us/azure/sre-agent/pricing-billing).
For general RBAC, consult [role definitions](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-definitions)
and [built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles).