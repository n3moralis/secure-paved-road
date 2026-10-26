mock_provider "google" {}

variables {
  project_id = "test-project"
  name       = "test"
  region     = "europe-west3"
  subnet = {
    cidr          = "10.10.0.0/20"
    pods_cidr     = "10.16.0.0/14"
    services_cidr = "10.20.0.0/20"
  }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = length(google_compute_firewall.deny_all_ingress) == 1
    error_message = "Logged default-deny ingress must exist by default."
  }

  assert {
    condition     = google_compute_subnetwork.nodes.private_ip_google_access == true
    error_message = "Private nodes need Private Google Access."
  }

  assert {
    condition     = length(google_compute_subnetwork.nodes.log_config) == 1
    error_message = "Flow logs must be on by default."
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 1
    error_message = "NAT must exist by default for private-node egress."
  }
}

run "nat_can_be_turned_off" {
  command = apply

  variables {
    nat = { enabled = false }
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 0 && length(google_compute_router.this) == 0
    error_message = "No router or NAT when nat.enabled = false."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    subnet = {
      cidr          = "10.10.0.0/33"
      pods_cidr     = "10.16.0.0/14"
      services_cidr = "10.20.0.0/20"
    }
  }

  expect_failures = [var.subnet]
}
