# Design decisions

Short ADRs: what was chosen, what was rejected, why. Revisit when the "why" changes.

## ADR-001 GKE Autopilot, not Standard

**Chosen:** Autopilot. Google operates nodes (hardened COS, Shielded VMs,
auto-upgrade, Workload Identity and NetworkPolicy always on).
**Rejected:** Standard — more knobs, more ways to be insecure, and node pools
cost money while idle.
**Trade-off:** no privileged pods or host access; that is a feature for a
paved road (security tools needing node access, e.g. Falco, would require
Standard or GKE-native alternatives).

## ADR-002 Keyless CI bound to repository ID and branch

**Chosen:** Workload Identity Federation. The provider accepts tokens only
from the repository's **numeric ID** (immutable; a deleted and re-created repo
with the same name does not match). The publisher identity can be assumed only
from `refs/heads/main`, so a pull request or fork can build and test but
never publish.
**Rejected:** service-account JSON keys (long-lived, leakable, need rotation).

## ADR-003 Deploy-time policy with Kyverno, not Binary Authorization

**Chosen:** Kyverno `verifyImages` (cosign keyless: signature must come from
this repository's workflow on `main`, SBOM attestation required) plus Pod
Security Standards `restricted`.
**Rejected (for now):** Binary Authorization — GKE-native and a strong option,
but Kyverno policies are portable, testable in CI and readable as code
reviews. Either satisfies "unsigned image never runs".

## ADR-004 Google-managed encryption at rest

**Chosen:** default Google-managed keys for registry and bucket.
**Rejected:** CMEK — adds a KMS key, IAM and cost; it mitigates threats
(key-access separation, crypto-shredding) that this demo does not have.
Would be the default in a regulated production environment.

## ADR-005 Ansible only for the one-time bootstrap

**Chosen:** Terraform owns cloud resources, Argo CD owns cluster state.
Ansible (`kubernetes.core.helm`) installs Argo CD once; after that Git is the
only way to change the cluster.
**Rejected:** Ansible managing Kubernetes objects continuously — that would
be a second source of truth competing with GitOps.

## ADR-006 CI never reaches the cluster

**Chosen:** pull-based GitOps. CI publishes signed images; Argo CD inside the
cluster pulls desired state from Git. The control plane accepts connections
only from the admin's IP.
**Rejected:** `kubectl apply` from CI — would require cluster credentials in
the most exposed component of the pipeline.

## Scanner triage (checkov)

Every skip is in the code next to the resource, with its reason.

| Check | Verdict | Reason |
|---|---|---|
| CKV_GCP_125 OIDC trust policy | **false positive** | only recognises `assertion.sub == 'repo:…'`; the condition pins the immutable repository ID, which is stronger |
| CKV_GCP_12 NetworkPolicy | not applicable | always on in Autopilot (Dataplane V2) |
| CKV_GCP_69 GKE metadata server | not applicable | always on in Autopilot |
| CKV_GCP_66 Binary Authorization | accepted, mitigated | Kyverno verifyImages, ADR-003 |
| CKV_GCP_61 intranode visibility | accepted | subnet flow logs on; cost without benefit for one service |
| CKV_GCP_65 Google Groups RBAC | accepted | needs Cloud Identity; single operator |
| CKV_GCP_84 CSEK on registry | accepted | ADR-004 |
| CKV_GCP_62 bucket access logs | mitigated | Data Access audit logs enabled for storage and registry |
| CKV_GCP_13 client certificates | **fixed** | `issue_client_certificate = false` |
| CKV_GCP_21 cluster labels | **fixed** | `resource_labels` |
| CKV2_GCP_18 network firewall | **fixed** | explicit logged default-deny ingress |

## ADR-007 One repository for the demo, split by ownership in production

**Chosen (here):** a single repository with one directory per cloud
(`platforms/<cloud>/`) and shared layers written once (`service/`,
`policies/`, `gitops/`, `tools/`). One place to read, one CI, one Security tab.
**Rejected:** a branch per cloud or environment — shared fixes need
cherry-picks to every branch, branches drift, and only the default branch is
visible and protected.
**In production I would split by owner and release cadence**, not by cloud:

| Repository | Owner | Why separate |
|---|---|---|
| Terraform modules (versioned, tagged) | platform team | consumers pin a version; changes are released, not pushed |
| Live infrastructure per team/environment | platform team | small blast radius, own state, own CODEOWNERS |
| Service template (GitHub template repo) + reusable workflows | platform team | teams adopt and upgrade on their own schedule |
| Admission policies | security team | own review and release, tested before rollout |
| GitOps config (Argo CD apps) | platform + service teams | CI bumps image digests here; app repos never touch the cluster |
| Service repositories | product teams | their code, the paved road's gates |

## ADR-008 Blocks: secure by default, configurable within guardrails

**Chosen:** every capability is a Terraform module (`modules/`) with secure
defaults, explicit knobs, validations that reject insecure inputs, and
`terraform test` suites on a mocked provider. Platforms only compose blocks.
**Why:** the paved road must be the easy path. A team gets the hardened result
by passing only required inputs; weakening a control is a visible input in a
diff, and some weakenings (public Kubernetes API, Editor on nodes, wildcard
CI refs, trust by repository name) are impossible.
**Rejected:** "fully configurable" modules that expose every provider argument
— they move every security decision to every consumer, which is exactly the
checklist model a paved road replaces.
**Trade-off:** a legitimate need outside the guardrails requires changing the
block (reviewed by its owner), not just a variable. That friction is intended.
