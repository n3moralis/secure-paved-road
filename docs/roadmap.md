# Roadmap

Each stage ends with something that can be **demonstrated failing safely**:
a guardrail is only real if you can show what it stops.

## Stage 1 — Foundation (Terraform)

- [ ] Blocks in `modules/` with secure defaults, validations and `terraform test` (mocked provider) — run in CI

- [ ] GCP project, billing linked, budget with alerts (first resource)
- [ ] State bucket (versioned, public access prevented) adopted into Terraform
- [ ] Data Access audit logs for storage and registry
- [ ] Workload Identity Federation: repository-ID-bound provider, publisher usable from `main` only
- [ ] Artifact Registry: immutable tags, cleanup policies, writer = CI publisher only
- [ ] VPC, private nodes, Cloud NAT, logged default-deny ingress
- [ ] GKE Autopilot: private nodes, API reachable from admin IP only, least-privilege node SA
- [ ] CI: fmt, validate, tflint, checkov → SARIF in code scanning; findings triaged in docs/decisions.md

**Demo:** a workflow on a feature branch tries to authenticate as the publisher → denied.

## Stage 2 — Paved-road service and supply chain

- [ ] Go service template: authn middleware (OIDC/JWT), `/metrics`, OpenTelemetry traces, structured logs, health probes
- [ ] Secrets only from Secret Manager via Workload Identity (no env secrets, no files in git)
- [ ] GHAS: CodeQL (Go), secret scanning + push protection, Dependabot; `govulncheck`
- [ ] Build (distroless / ko), SBOM (syft), cosign keyless sign + SBOM attestation, GitHub build provenance
- [ ] All actions pinned to commit SHAs
- [ ] Merge gates as code: Terraform `github` provider manages rulesets and required checks

**Demo:** a PR that leaks a token or adds a vulnerable dependency cannot be merged.

## Stage 3 — Deploy-time policy

- [ ] Ansible playbook bootstraps Argo CD once (`kubernetes.core.helm`), then GitOps only
- [ ] Kyverno: verifyImages (signature from this repo's main workflow + SBOM attestation required)
- [ ] Pod Security Standards `restricted`, default-deny NetworkPolicy per namespace
- [ ] Kyverno policies tested in CI (`kyverno test`)

**Demo:** deploy an unsigned image by hand → admission denied, with the reason.

## Stage 4 — Observability and security KPIs

- [ ] Prometheus + Grafana (kube-prometheus-stack), Jaeger for traces
- [ ] KPI exporter in Go: GHAS code-scanning, secret-scanning and Dependabot alerts → Prometheus metrics
- [ ] Dashboard: open alerts by severity, mean time to remediate, % of repos with gates, policy denials

**Demo:** merge a fix → alert closes → MTTR on the dashboard moves.

## Stage 5 — AI-generated code

- [ ] An "AI-written" PR with an injection flaw is stopped by CodeQL at the merge gate
- [ ] Review checklist for AI-assisted changes (provenance in PR template, mandatory human review of auth/crypto/IO code)
- [ ] Write-up: where AI helps triage (alert summaries, fix suggestions) and where it must not decide

## Presentation (10–12 slides + 5-minute live demo)

1. Problem: security as a checklist vs a paved road
2. Architecture (one diagram)
3. Keyless CI and why the ID matters
4. Supply chain: SBOM, signature, provenance
5. Merge gates as code
6. Admission: the cluster says no
7. KPIs: what leadership sees
8. AI-generated code
9. Scanner triage: false positives handled, not ignored
10. What I would do next in production (CMEK, Binary Authorization, org policies, Mimir)
