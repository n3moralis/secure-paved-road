# Least-privilege node identity instead of the default compute service account
# (which has Editor on the project).
resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = substr("${var.name}-nodes", 0, 30)
  display_name = "GKE nodes of ${var.name} (least privilege)"
}

resource "google_project_iam_member" "nodes" {
  for_each = var.node_service_account_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_artifact_registry_repository_iam_member" "nodes_pull" {
  for_each = var.pull_registries

  project    = var.project_id
  location   = each.value.location
  repository = each.value.repository
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.nodes.email}"
}

# Autopilot: Google runs the nodes (hardened COS, Shielded VMs, auto-upgrade,
# Workload Identity and NetworkPolicy always on). We own workloads and policy.
resource "google_container_cluster" "this" {
  #checkov:skip=CKV_GCP_12:Autopilot always enforces NetworkPolicy (Dataplane V2); not configurable
  #checkov:skip=CKV_GCP_69:Autopilot always runs the GKE metadata server (Workload Identity); not configurable
  #checkov:skip=CKV_GCP_66:Deploy-time image policy is enforced by Kyverno verifyImages, see ADR-003
  #checkov:skip=CKV_GCP_61:Subnet flow logs are on (gcp-network); intranode visibility adds cost without benefit here
  #checkov:skip=CKV_GCP_65:Google Groups for RBAC needs Cloud Identity/Workspace; single-operator project
  project  = var.project_id
  name     = var.name
  location = var.region

  enable_autopilot    = true
  deletion_protection = var.deletion_protection

  resource_labels = merge({ component = "gke" }, var.labels)

  network    = var.network_id
  subnetwork = var.subnet_id

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # No legacy client-certificate auth: access only via IAM.
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Private nodes; the API endpoint is public but reachable only from admin_cidrs.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false

    dynamic "cidr_blocks" {
      for_each = var.admin_cidrs
      content {
        cidr_block   = cidr_blocks.value
        display_name = "admin"
      }
    }
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.nodes.email
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"] # access is limited by IAM, not scopes
    }
  }

  depends_on = [
    google_project_iam_member.nodes,
    google_artifact_registry_repository_iam_member.nodes_pull,
  ]
}
