# GKE foundation = composition of blocks. No resources are defined here:
# every capability comes from a tested module in /modules, configured below.

module "baseline" {
  source = "../../../../modules/gcp-project-baseline"

  project_id = var.project_id
  budget = {
    billing_account = var.billing_account
    amount          = var.budget_amount
    display_name    = "secure-paved-road-gke"
  }
}

module "state" {
  source = "../../../../modules/gcp-state-bucket"

  project_id = var.project_id
  name       = "${var.project_id}-tfstate"
  location   = var.region

  depends_on = [module.baseline]
}

# The bucket is created once by hand (it must exist before Terraform can use
# it as a backend), then adopted here so its settings are code.
import {
  to = module.state.google_storage_bucket.this
  id = "${var.project_id}-tfstate"
}

module "ci_identity" {
  source = "../../../../modules/gcp-ci-identity"

  project_id    = var.project_id
  repository    = var.github_repository
  repository_id = var.github_repository_id
  # default: one identity "ci-publisher", usable from refs/heads/main only

  depends_on = [module.baseline]
}

module "registry" {
  source = "../../../../modules/gcp-registry"

  project_id = var.project_id
  location   = var.region
  writers = {
    ci_publisher = module.ci_identity.members["ci-publisher"]
  }

  depends_on = [module.baseline]
}
