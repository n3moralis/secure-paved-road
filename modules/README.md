# Blocks

Every capability is a block: one job, secure defaults, explicit knobs,
validations that refuse insecure configurations, and tests that run without a
cloud account (`terraform test` with a mocked provider). Platforms in
`/platforms` only **compose** blocks — they define no resources of their own.

## Rules for every block

1. **Secure by default.** Using a block with only its required inputs gives the
   hardened result. Weakening something is an explicit input, visible in review.
2. **Configurable within guardrails.** Knobs exist for legitimate differences
   between systems (sizes, ranges, retention, which refs may publish). Inputs
   that would make a block insecure are rejected by validation, not documented
   as "don't do this".
3. **No provider configuration inside.** Project, region and labels come from
   the composition.
4. **Static keys for `for_each`.** Maps keyed by labels, so plans work before
   the resources they reference exist.
5. **Tested.** `tests/` proves the secure defaults and that insecure inputs fail.
6. **Scanner findings triaged in place.** Every `checkov:skip` carries its reason.

## Catalog (GCP)

| Block | Provides (contract) | Secure defaults | Main knobs | Refuses |
|---|---|---|---|---|
| `gcp-project-baseline` | APIs, cost guard, audit trail (C9, C10) | Data Access audit logs on; forecast alert | `services`, `budget`, `data_access_audit_services` | budget ≤ 0, thresholds outside (0, 2] |
| `gcp-state-bucket` | Terraform state | versioned, never public, uniform access, `prevent_destroy` | `keep_versions` | no history |
| `gcp-ci-identity` | keyless CI (C4) | repo-ID-bound provider; one publisher from `main` | `service_accounts` with exact `allowed_refs` | repo name instead of ID, wildcard refs, identity without refs |
| `gcp-registry` | OCI registry (C3) | immutable tags; keep-recent + age cleanup; no access unless granted | `writers`, `readers`, retention | — (opt-outs are explicit inputs) |
| `gcp-network` | private networking (C2) | no auto subnets; Private Google Access; flow logs; NAT; logged default-deny | `subnet`, `flow_logs`, `nat`, `deny_all_ingress` | invalid CIDRs, sampling outside (0, 1] |
| `gcp-gke-autopilot` | cluster (C1, C5, C8) | private nodes; no client certs; release channel; least-privilege node SA; deletion protection | `admin_cidrs`, `release_channel`, `pull_registries`, `deletion_protection` | API open to the internet, no release channel, Owner/Editor on nodes |

Planned: `aws-*` and `azure-*` blocks with the same contract (see
[docs/platform-contract.md](../docs/platform-contract.md)), and the
Kubernetes-layer blocks (Kyverno policy sets, GitOps components) in stage 3.

## Run the tests

```bash
for m in modules/*/; do terraform -chdir="$m" init -backend=false && terraform -chdir="$m" test; done
```
