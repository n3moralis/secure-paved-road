# Keyless CI: GitHub Actions exchanges its OIDC token for a short-lived Google
# token. No service-account key exists anywhere, so there is nothing to leak.

resource "google_iam_workload_identity_pool" "this" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "OIDC trust for ${var.repository} only"
}

resource "google_iam_workload_identity_pool_provider" "this" {
  # False positive: the check only recognises "assertion.sub == 'repo:…'".
  # Pinning the immutable repository_id is stronger than a name-based sub.
  #checkov:skip=CKV_GCP_125:Condition pins the immutable repository_id (stronger than a sub/name match)
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.this.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"          = "assertion.sub"
    "attribute.repository"    = "assertion.repository"
    "attribute.repository_id" = "assertion.repository_id"
    "attribute.ref"           = "assertion.ref"
    "attribute.repo_ref"      = "assertion.repository_id + ':' + assertion.ref"
  }

  # Gate at the provider: tokens from any other repository are rejected
  # before any IAM binding is evaluated.
  attribute_condition = "assertion.repository_id == '${var.repository_id}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "this" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = "Assumed by ${var.repository} via WIF from: ${join(", ", each.value.allowed_refs)}. No keys."
}

locals {
  # One binding per (identity, ref). Keys are static strings, so for_each is
  # known at plan time even before the service accounts exist.
  bindings = merge([
    for sa_key, sa in var.service_accounts : {
      for ref in sa.allowed_refs : "${sa_key}|${ref}" => { sa_key = sa_key, ref = ref }
    }
  ]...)
}

resource "google_service_account_iam_member" "wif" {
  for_each = local.bindings

  service_account_id = google_service_account.this[each.value.sa_key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.this.name}/attribute.repo_ref/${var.repository_id}:${each.value.ref}"
}
