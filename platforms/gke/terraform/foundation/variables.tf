variable "project_id" {
  description = "GCP project that holds the whole demo platform."
  type        = string
}

variable "region" {
  description = "Region for the registry, the state bucket and (in platform/) the cluster."
  type        = string
  default     = "europe-west3" # Frankfurt
}

variable "billing_account" {
  description = "Billing account ID (XXXXXX-XXXXXX-XXXXXX) the budget is attached to."
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget in the billing account's currency. Alerts at 50/90/100 % and on forecast."
  type        = number
  default     = 20
}

variable "github_repository" {
  description = "owner/name of the GitHub repository allowed to authenticate (informational, used in names/outputs)."
  type        = string
  default     = "n3moralis/secure-paved-road"
}

variable "github_repository_id" {
  description = <<-EOT
    Numeric ID of the GitHub repository. Trust is bound to the ID, not the name,
    so a deleted-and-recreated repository with the same name cannot inherit it.
    Get it with: curl -s https://api.github.com/repos/OWNER/NAME | jq .id
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "github_repository_id must be the numeric repository ID."
  }
}
