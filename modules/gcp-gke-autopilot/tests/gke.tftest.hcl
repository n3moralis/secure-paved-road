mock_provider "google" {}

variables {
  project_id  = "test-project"
  name        = "test"
  region      = "europe-west3"
  network_id  = "projects/test-project/global/networks/test"
  subnet_id   = "projects/test-project/regions/europe-west3/subnetworks/nodes"
  admin_cidrs = ["203.0.113.10/32"]
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = google_container_cluster.this.deletion_protection == true
    error_message = "Deletion protection must default to on."
  }

  assert {
    condition     = google_container_cluster.this.private_cluster_config[0].enable_private_nodes == true
    error_message = "Nodes must be private."
  }

  assert {
    condition     = google_container_cluster.this.master_auth[0].client_certificate_config[0].issue_client_certificate == false
    error_message = "No legacy client certificates."
  }

  assert {
    condition     = google_container_cluster.this.release_channel[0].channel == "REGULAR"
    error_message = "Clusters must be on a release channel."
  }
}

run "rejects_api_open_to_internet" {
  command = plan

  variables {
    admin_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.admin_cidrs]
}

run "rejects_editor_on_nodes" {
  command = plan

  variables {
    node_service_account_roles = ["roles/editor"]
  }

  expect_failures = [var.node_service_account_roles]
}

run "rejects_no_release_channel" {
  command = plan

  variables {
    release_channel = "UNSPECIFIED"
  }

  expect_failures = [var.release_channel]
}
