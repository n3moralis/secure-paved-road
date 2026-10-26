terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }

  # Same bucket as foundation/, prefix "platform" (see docs/gke-stage-1-runbook.md).
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = {
    managed-by = "terraform"
    project    = "secure-paved-road"
    layer      = "platform"
  }
}
