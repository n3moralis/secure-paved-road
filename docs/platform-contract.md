# Platform contract

The paved road is portable because it depends on a **contract**, not on a
cloud. Everything above the line is written once; a new platform is done when
it satisfies every row below the line.

```
 shared, written once   service/ · policies/ · gitops/ · tools/posture/ · CI gates · security drill
 ─────────────────────────────────────────────────────────────────────────────────────────────────
 per platform           platforms/<name>/  — fulfils the contract below
```

## What every platform must provide

| # | Capability | Contract (what the shared layers rely on) |
|---|---|---|
| C1 | Kubernetes cluster | conformant, current minus one minor version at most; API reachable only from admin networks |
| C2 | Private nodes | no public IPs on nodes; egress through NAT or a proxy |
| C3 | OCI registry | push from CI only; nodes pull read-only; immutable tags; stores cosign signatures and attestations |
| C4 | Keyless CI identity | CI exchanges its OIDC token for short-lived credentials; bound to repository ID and `main`; no static keys |
| C5 | Workload identity | pods get cloud/secret access through their service account, never through mounted keys |
| C6 | Secret store | secrets reach pods through C5 (cloud secret manager or Vault); nothing secret in git |
| C7 | Admission control | cluster accepts a Kyverno installation (validating + mutating webhooks) |
| C8 | Default-deny networking | NetworkPolicy enforced |
| C9 | Audit trail | control-plane and registry access are logged |
| C10 | Cost guard | budget/alert or hard resource limit; `platform` layer destroyable in one command |

## How each platform fulfils it

| | GKE (GCP) | k3s (homelab) | EKS (AWS) | AKS (Azure) |
|---|---|---|---|---|
| Status | 🔄 stage 1 | 📋 planned | 📋 planned | 📋 planned |
| C1 cluster | GKE Autopilot | k3s on Proxmox VMs (Terraform + Ansible) | EKS | AKS |
| C2 private nodes | private nodes + Cloud NAT | segmented VLAN, firewall egress allowlist | private subnets + NAT GW | private cluster + NAT GW |
| C3 registry | Artifact Registry | GitLab container registry or Harbor | ECR | ACR |
| C4 keyless CI | Workload Identity Federation | GitLab OIDC → Vault (JWT auth) | IAM OIDC provider + role | federated credential on managed identity |
| C5 workload identity | GKE Workload Identity | Vault Kubernetes auth | EKS Pod Identity | Entra Workload ID |
| C6 secrets | Secret Manager | Vault | Secrets Manager | Key Vault |
| C7 admission | Kyverno | Kyverno | Kyverno | Kyverno |
| C8 networking | Dataplane V2 (always on) | Cilium | VPC CNI network policies or Cilium | Azure CNI + Cilium |
| C9 audit | Cloud Audit Logs | k3s audit policy + Loki | CloudTrail + EKS control-plane logs | Activity Log + diagnostic settings |
| C10 cost guard | billing budget | n/a (own hardware) | AWS Budgets | Cost Management budget |

## Definition of done for a new platform

1. `platforms/<name>/` passes the shared CI (`validate`, `tflint`, `checkov`) — added as one matrix entry.
2. The **same** `service/`, `policies/` and `gitops/` deploy without edits (only a GitOps overlay with registry and identity values).
3. The **security drill** runs against it and every control holds.
4. A runbook `docs/<name>-runbook.md` and an ADR for every place it deviates from the contract.
