variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "repository_id" {
  type    = string
  default = "images"
}

variable "description" {
  type    = string
  default = "Signed images; cosign signatures and attestations are stored next to them"
}

variable "immutable_tags" {
  description = "A tag can never point to different content. Disable only with a written reason (ADR)."
  type        = bool
  default     = true
}

variable "keep_recent" {
  description = "Always keep this many most recent versions, whatever their age."
  type        = number
  default     = 20
}

variable "delete_older_than_days" {
  description = "Delete versions older than this (keep_recent still wins). null disables age-based cleanup."
  type        = number
  default     = 30
  nullable    = true
}

variable "writers" {
  description = "label => IAM member allowed to push (e.g. { ci = \"serviceAccount:…\" }). Labels must be static strings."
  type        = map(string)
  default     = {}
}

variable "readers" {
  description = "label => IAM member allowed to pull."
  type        = map(string)
  default     = {}
}

resource "google_artifact_registry_repository" "this" {
  #checkov:skip=CKV_GCP_84:Google-managed encryption; CMEK is a per-environment decision (ADR-004)
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = var.description

  docker_config {
    immutable_tags = var.immutable_tags
  }

  cleanup_policy_dry_run = false

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.keep_recent
    }
  }

  dynamic "cleanup_policies" {
    for_each = var.delete_older_than_days == null ? [] : [var.delete_older_than_days]
    content {
      id     = "delete-older-than-${cleanup_policies.value}d"
      action = "DELETE"
      condition {
        tag_state  = "ANY"
        older_than = "${cleanup_policies.value * 86400}s"
      }
    }
  }
}

resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each = var.writers

  project    = var.project_id
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.writer"
  member     = each.value
}

resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = var.readers

  project    = var.project_id
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

output "url" {
  description = "Image prefix: <url>/<image>"
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}

output "repository_id" {
  value = google_artifact_registry_repository.this.repository_id
}

output "location" {
  value = google_artifact_registry_repository.this.location
}
