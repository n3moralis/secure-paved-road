output "cluster_name" {
  value = module.cluster.name
}

output "get_credentials" {
  description = "Run this to point kubectl at the cluster"
  value       = module.cluster.get_credentials
}
