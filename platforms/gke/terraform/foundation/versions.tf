terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }

  # Partial configuration: bucket and prefix come from -backend-config
  # (see docs/gke-stage-1-runbook.md). The bucket itself is created once with
  # gcloud and then adopted by this root module (import block in state.tf).
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Budgets API and other billing-scoped calls need a quota project when
  # Terraform runs with user credentials (gcloud ADC).
  billing_project       = var.project_id
  user_project_override = true

  default_labels = {
    managed-by = "terraform"
    project    = "secure-paved-road"
    layer      = "foundation"
  }
}
