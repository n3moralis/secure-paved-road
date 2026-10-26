variable "project_id" {
  type = string
}

variable "name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "location" {
  type = string
}

variable "keep_versions" {
  description = "Non-current versions of each state file to keep (history for recovery)."
  type        = number
  default     = 10

  validation {
    condition     = var.keep_versions >= 1
    error_message = "Keep at least one previous version of the state."
  }
}

resource "google_storage_bucket" "this" {
  #checkov:skip=CKV_GCP_62:Legacy usage-log buckets are superseded by Data Access audit logs (gcp-project-baseline)
  project  = var.project_id
  name     = var.name
  location = var.location

  # Not configurable on purpose: a state bucket is never public, never
  # ACL-based, never unversioned.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.keep_versions
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "name" {
  value = google_storage_bucket.this.name
}
