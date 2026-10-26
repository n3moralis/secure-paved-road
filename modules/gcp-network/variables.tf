variable "project_id" {
  type = string
}

variable "name" {
  description = "Prefix for the VPC, router and NAT."
  type        = string
}

variable "region" {
  type = string
}

variable "subnet" {
  description = "Node subnet and its secondary ranges (pods, services) for VPC-native clusters."
  type = object({
    name          = optional(string, "nodes")
    cidr          = string
    pods_cidr     = string
    services_cidr = string
  })

  validation {
    condition     = alltrue([for c in [var.subnet.cidr, var.subnet.pods_cidr, var.subnet.services_cidr] : can(cidrnetmask(c))])
    error_message = "subnet.cidr, pods_cidr and services_cidr must be valid IPv4 CIDRs."
  }
}

variable "flow_logs" {
  description = "VPC flow logs on the node subnet: evidence for incident response."
  type = object({
    enabled  = optional(bool, true)
    sampling = optional(number, 0.2)
    interval = optional(string, "INTERVAL_10_MIN")
  })
  default = {}

  validation {
    condition     = var.flow_logs.sampling > 0 && var.flow_logs.sampling <= 1
    error_message = "flow_logs.sampling must be in (0, 1]."
  }
}

variable "nat" {
  description = "Cloud NAT for egress from private nodes. Disable only if egress goes through another path (proxy, PSC)."
  type = object({
    enabled    = optional(bool, true)
    log_filter = optional(string, "ERRORS_ONLY")
  })
  default = {}
}

variable "deny_all_ingress" {
  description = "Explicit, logged lowest-priority deny for all ingress. Platform allow rules sit above it."
  type        = bool
  default     = true
}
