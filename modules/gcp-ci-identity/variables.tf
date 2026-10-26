variable "project_id" {
  type = string
}

variable "pool_id" {
  type    = string
  default = "github"
}

variable "provider_id" {
  type    = string
  default = "github-oidc"
}

variable "repository" {
  description = "owner/name — informational (descriptions only). Trust is bound to repository_id."
  type        = string
}

variable "repository_id" {
  description = <<-EOT
    Numeric GitHub repository ID. Immutable: a deleted and re-created
    repository with the same name gets a new ID and is NOT trusted.
    curl -s https://api.github.com/repos/OWNER/NAME | jq .id
  EOT
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.repository_id))
    error_message = "repository_id must be the numeric repository ID, not the name."
  }
}

variable "service_accounts" {
  description = <<-EOT
    Identities CI may assume, keyed by account_id. Each lists the exact git
    refs allowed to assume it. Default: one publisher, usable from main only.
    Grant the identity its permissions in the block that owns the resource
    (e.g. gcp-registry writers), not here.
  EOT
  type = map(object({
    display_name = string
    allowed_refs = optional(list(string), ["refs/heads/main"])
  }))
  default = {
    "ci-publisher" = {
      display_name = "CI publisher (main only)"
    }
  }

  validation {
    condition = alltrue(flatten([
      for sa in values(var.service_accounts) : [
        for r in sa.allowed_refs : can(regex("^refs/(heads|tags)/[^*?\\[\\]]+$", r))
      ]
    ]))
    error_message = "allowed_refs must be exact refs (refs/heads/… or refs/tags/…); wildcards are not allowed."
  }

  validation {
    condition     = alltrue([for sa in values(var.service_accounts) : length(sa.allowed_refs) > 0])
    error_message = "Every identity needs at least one allowed ref."
  }
}
