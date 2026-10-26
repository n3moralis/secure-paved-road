variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "region" {
  description = "Autopilot clusters are regional."
  type        = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "pods_range_name" {
  type    = string
  default = "pods"
}

variable "services_range_name" {
  type    = string
  default = "services"
}

variable "admin_cidrs" {
  description = "Public CIDRs allowed to reach the Kubernetes API. CI never needs it (pull-based GitOps)."
  type        = list(string)

  validation {
    condition = length(var.admin_cidrs) > 0 && alltrue([
      for c in var.admin_cidrs : can(cidrnetmask(c)) && !contains(["0.0.0.0/0", "0.0.0.0/1", "128.0.0.0/1"], c)
    ])
    error_message = "admin_cidrs must be valid CIDRs and must not open the API to the internet."
  }
}

variable "release_channel" {
  type    = string
  default = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Use a release channel (RAPID, REGULAR, STABLE): clusters must receive security patches automatically."
  }
}

variable "deletion_protection" {
  description = "Secure default true. Demos set false explicitly so the cluster can be destroyed after each session."
  type        = bool
  default     = true
}

variable "node_service_account_roles" {
  description = "Project roles for the dedicated node identity. Default is the minimum GKE needs."
  type        = set(string)
  default     = ["roles/container.defaultNodeServiceAccount"]

  validation {
    condition     = length(setintersection(var.node_service_account_roles, ["roles/owner", "roles/editor"])) == 0
    error_message = "Nodes must not get Owner or Editor."
  }
}

variable "pull_registries" {
  description = "label => { location, repository } Artifact Registry repos the nodes may pull from (read-only)."
  type = map(object({
    location   = string
    repository = string
  }))
  default = {}
}

variable "labels" {
  type    = map(string)
  default = {}
}
