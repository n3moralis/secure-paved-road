# GKE platform = composition of blocks. Destroyed after every session.

module "network" {
  source = "../../../../modules/gcp-network"

  project_id = var.project_id
  name       = var.cluster_name
  region     = var.region
  subnet = {
    cidr          = var.subnet_cidr
    pods_cidr     = var.pods_cidr
    services_cidr = var.services_cidr
  }
}

module "cluster" {
  source = "../../../../modules/gcp-gke-autopilot"

  project_id          = var.project_id
  name                = var.cluster_name
  region              = var.region
  network_id          = module.network.network_id
  subnet_id           = module.network.subnet_id
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name
  admin_cidrs         = var.admin_cidrs

  # Secure default is true; this demo is torn down after each session.
  deletion_protection = var.deletion_protection

  pull_registries = {
    images = { location = var.region, repository = "images" } # created in foundation/
  }
}
