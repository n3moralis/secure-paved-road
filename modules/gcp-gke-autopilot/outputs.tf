output "name" {
  value = google_container_cluster.this.name
}

output "node_service_account" {
  value = google_service_account.nodes.email
}

output "get_credentials" {
  description = "Run this to point kubectl at the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${var.region} --project ${var.project_id}"
}
