output "project_number" {
  value = data.google_project.this.number
}

output "enabled_services" {
  value = sort([for s in google_project_service.this : s.service])
}

output "budget_enabled" {
  value = length(google_billing_budget.this) == 1
}
