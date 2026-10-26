variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west3"
}

variable "cluster_name" {
  type    = string
  default = "paved-road"
}

variable "admin_cidrs" {
  description = <<-EOT
    Public CIDRs allowed to reach the Kubernetes API (your laptop's egress IP
    as x.x.x.x/32). Nothing else can talk to the control plane; GitHub Actions
    never needs to, because Argo CD pulls from inside the cluster.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0 && alltrue([for c in var.admin_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"])
    error_message = "admin_cidrs must be valid CIDRs and must not be 0.0.0.0/0."
  }
}

variable "deletion_protection" {
  description = "false for the demo, so 'terraform destroy' removes the cluster after each session."
  type        = bool
  default     = false
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.16.0.0/14"
}

variable "services_cidr" {
  type    = string
  default = "10.20.0.0/20"
}
