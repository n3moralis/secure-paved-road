# Identifiers only, no secrets: useless without a valid GitHub OIDC token from
# the bound repository and branch.

output "state_bucket" {
  value = module.state.name
}

output "registry" {
  description = "GitHub variable GCP_REGISTRY"
  value       = module.registry.url
}

output "wif_provider" {
  description = "GitHub variable GCP_WIF_PROVIDER"
  value       = module.ci_identity.provider_name
}

output "ci_publisher_email" {
  description = "GitHub variable GCP_CI_PUBLISHER"
  value       = module.ci_identity.service_account_emails["ci-publisher"]
}
