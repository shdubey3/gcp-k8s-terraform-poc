# Root module - Orchestrates networking and GKE cluster creation

module "networking" {
  source = "./modules/networking"

  project_id = var.project_id
  region     = var.cluster.region
  labels     = var.labels

  # Network identity
  vpc_name    = var.network.vpc_name
  subnet_name = var.network.subnet_name

  # CIDR ranges
  vpc_cidr                      = var.network.vpc_cidr
  subnet_cidr                   = var.network.subnet_cidr
  pods_secondary_range_name     = var.network.pods_range_name
  pods_secondary_cidr           = var.network.pods_cidr
  services_secondary_range_name = var.network.services_range_name
  services_secondary_cidr       = var.network.services_cidr

  # Access control
  allowed_ssh_cidr = var.network.allowed_ssh_cidr
}

module "gke" {
  source = "./modules/gke"

  project_id = var.project_id
  region     = var.cluster.region
  labels     = var.labels

  # Cluster identity
  cluster_name    = var.cluster.name
  gke_version     = var.cluster.gke_version
  release_channel = var.cluster.release_channel

  # Networking – self-links ensure unambiguous resource references
  network_self_link             = module.networking.vpc_self_link
  subnet_self_link              = module.networking.subnet_self_link
  pods_secondary_range_name     = var.network.pods_range_name
  services_secondary_range_name = var.network.services_range_name

  # API server access (sourced from MY_CIDR via setenv.sh)
  master_authorized_cidr = var.master_authorized_cidr

  # Node placement
  node_locations    = var.cluster.node_locations
  max_pods_per_node = var.cluster.max_pods_per_node

  # Node pool
  node_pool_name     = var.node_pool.name
  initial_node_count = var.node_pool.initial_count
  min_node_count     = var.node_pool.min_count
  max_node_count     = var.node_pool.max_count
  machine_type       = var.node_pool.machine_type
  disk_size_gb       = var.node_pool.disk_size_gb
  disk_type          = var.node_pool.disk_type
  image_type         = var.node_pool.image_type

  # Node Auto-Provisioning
  autoprovisioning_min_cpu    = var.autoprovisioning.min_cpu
  autoprovisioning_max_cpu    = var.autoprovisioning.max_cpu
  autoprovisioning_min_memory = var.autoprovisioning.min_memory
  autoprovisioning_max_memory = var.autoprovisioning.max_memory
  autoprovisioning_locations  = var.autoprovisioning.locations

  depends_on = [module.networking]
}
