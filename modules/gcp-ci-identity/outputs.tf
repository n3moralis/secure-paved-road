output "provider_name" {
  description = "For google-github-actions/auth 'workload_identity_provider'"
  value       = google_iam_workload_identity_pool_provider.this.name
}

output "service_account_emails" {
  description = "account_id => email, for google-github-actions/auth 'service_account'"
  value       = { for k, sa in google_service_account.this : k => sa.email }
}

output "members" {
  description = "account_id => IAM member string, to grant permissions in other blocks"
  value       = { for k, sa in google_service_account.this : k => "serviceAccount:${sa.email}" }
}
