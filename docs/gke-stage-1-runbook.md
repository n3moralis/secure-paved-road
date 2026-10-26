# GKE — stage 1 runbook: foundation and cluster

Time: ~3–4 h the first time (most of it waiting for APIs and the cluster).
Run everything from the laptop. No credentials are written to disk except
gcloud's own ADC; nothing secret goes into git.

## 0. Tools

```bash
gcloud version          # Google Cloud CLI
gcloud components install gke-gcloud-auth-plugin   # or the distro package google-cloud-cli-gke-gcloud-auth-plugin
terraform version       # >= 1.9
kubectl version --client
jq --version
```

## 1. GitHub repository (first: its ID is needed by Terraform)

1. New **public** repository `secure-paved-road`, license Apache-2.0, no README.
2. Settings → *Code security*: Secret scanning **on**, Push protection **on**,
   Dependabot alerts **on**, Code scanning → CodeQL **Default** setup.
3. Settings → *Actions → General*: Workflow permissions **Read repository contents**.
4. Note the repository ID:
   ```bash
   curl -s https://api.github.com/repos/n3moralis/secure-paved-road | jq .id
   ```

## 2. GCP project, billing, login

```bash
export P=paved-road-$(openssl rand -hex 3)      # project IDs are global; keep it
echo "$P"
gcloud auth login
gcloud projects create "$P" --name="secure paved road"
gcloud billing accounts list
gcloud billing projects link "$P" --billing-account=XXXXXX-XXXXXX-XXXXXX
gcloud config set project "$P"
gcloud auth application-default login
gcloud auth application-default set-quota-project "$P"
gcloud services enable cloudresourcemanager.googleapis.com serviceusage.googleapis.com storage.googleapis.com
```

## 3. State bucket (once, by hand — Terraform adopts it in step 4)

```bash
gcloud storage buckets create "gs://$P-tfstate" --location=europe-west3 \
  --uniform-bucket-level-access --public-access-prevention
```

## 4. Foundation

```bash
cd platforms/gke/terraform/foundation
cp terraform.tfvars.example terraform.tfvars     # fill: project_id, billing_account, github_repository_id
terraform init -backend-config="bucket=$P-tfstate" -backend-config="prefix=foundation"
terraform providers lock -platform=linux_amd64    # CI runs on linux_amd64; add your laptop's platform too
terraform fmt
terraform plan -out=tfplan                         # expect: 1 to import, ~25 to add
terraform apply tfplan && rm tfplan
terraform output
```

Check: Billing → Budgets shows `secure-paved-road-gke`; IAM → Workload Identity
Federation shows pool `github`.

> A destroyed WIF pool is soft-deleted for 30 days and its ID cannot be reused
> in that time — foundation is meant to stay.

## 5. Platform (cluster)

```bash
cd ../platform
curl -s https://ifconfig.me; echo                   # your egress IP → admin_cidrs as x.x.x.x/32
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config="bucket=$P-tfstate" -backend-config="prefix=platform"
terraform providers lock -platform=linux_amd64
terraform fmt
terraform plan -out=tfplan
terraform apply tfplan && rm tfplan                 # ~10 min
eval "$(terraform output -raw get_credentials)"
kubectl get ns
```

Smoke test (Autopilot creates nodes on demand — the first pod takes a minute or two):
```bash
kubectl run smoke --image=registry.k8s.io/pause:3.10 --restart=Never
kubectl get pod smoke -w           # Running → Ctrl-C
kubectl delete pod smoke
```

Negative test (the control plane must refuse other networks): from a phone
hotspot, `kubectl get ns` must time out.

## 6. Repository variables (not secrets — identifiers only)

GitHub → Settings → *Secrets and variables → Actions → Variables*:

| Variable | Value |
|---|---|
| `GCP_WIF_PROVIDER` | `terraform output -raw wif_provider` (foundation) |
| `GCP_CI_PUBLISHER` | `terraform output -raw ci_publisher_email` |
| `GCP_REGISTRY` | `terraform output -raw registry` |

## 7. First commit through the gate

```bash
git switch -c feat/foundation
git add . && git status            # no *.tfvars, no tfplan, .terraform.lock.hcl included
git commit -m "feat: stage 1 foundation and private GKE Autopilot"
git push -u origin feat/foundation
```
Open a PR → `terraform` workflow green, checkov results in the Security tab
→ merge. Then Settings → *Rules → Rulesets* for `main`: require a pull
request, require status checks `modules`, `validate (gke, foundation)`, `validate (gke, platform)`,
`checkov`, block force pushes and deletion. (Stage 2 moves this ruleset into
Terraform.)

## 8. End of every session

```bash
cd platforms/gke/terraform/platform && terraform destroy     # cluster, NAT, VPC — the parts that cost money
```
Foundation stays (cents per month).
