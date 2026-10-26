variable "project_id" {
  description = "Project to configure."
  type        = string
}

variable "services" {
  description = "APIs to enable. The default covers every gcp-* block in this repository."
  type        = set(string)
  default = [
    "artifactregistry.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
}

variable "budget" {
  description = <<-EOT
    Monthly budget with e-mail alerts to the billing admins. Amount is in the
    billing account's currency. Set to null only if cost is guarded elsewhere
    (e.g. an organisation-level budget).
  EOT
  type = object({
    billing_account = string
    amount          = number
    display_name    = optional(string, "platform")
    thresholds      = optional(list(number), [0.5, 0.9, 1.0])
    forecast_alert  = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.budget == null || try(var.budget.amount > 0 && alltrue([for t in var.budget.thresholds : t > 0 && t <= 2]), false)
    error_message = "budget.amount must be > 0 and every threshold in (0, 2]."
  }
}

variable "data_access_audit_services" {
  description = "Services whose Data Access audit logs (read and write) are enabled. Off by default in GCP."
  type        = set(string)
  default     = ["storage.googleapis.com", "artifactregistry.googleapis.com"]
}
