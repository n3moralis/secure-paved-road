resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "nodes" {
  project       = var.project_id
  name          = var.subnet.name
  network       = google_compute_network.this.id
  region        = var.region
  ip_cidr_range = var.subnet.cidr

  # Nodes have no public IPs; Google APIs are reached privately.
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.subnet.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.subnet.services_cidr
  }

  dynamic "log_config" {
    for_each = var.flow_logs.enabled ? [var.flow_logs] : []
    content {
      aggregation_interval = log_config.value.interval
      flow_sampling        = log_config.value.sampling
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}

resource "google_compute_firewall" "deny_all_ingress" {
  count = var.deny_all_ingress ? 1 : 0

  project   = var.project_id
  name      = "${var.name}-deny-all-ingress"
  network   = google_compute_network.this.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "this" {
  count = var.nat.enabled ? 1 : 0

  project = var.project_id
  name    = "${var.name}-router"
  network = google_compute_network.this.id
  region  = var.region
}

resource "google_compute_router_nat" "this" {
  count = var.nat.enabled ? 1 : 0

  project                            = var.project_id
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = var.nat.log_filter
  }
}
