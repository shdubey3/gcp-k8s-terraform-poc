# Root module - Orchestrates networking and GKE cluster creation

module "networking" {
  source = "./modules/networking"

  project_id                    = var.project_id
  region                        = var.region
  vpc_name                      = var.vpc_name
  vpc_cidr                      = var.vpc_cidr
  subnet_name                   = var.subnet_name
  subnet_cidr                   = var.subnet_cidr
  pods_secondary_range_name     = var.pods_secondary_range_name
  pods_secondary_cidr           = var.pods_secondary_cidr
  services_secondary_range_name = var.services_secondary_range_name
  services_secondary_cidr       = var.services_secondary_cidr
  allowed_ssh_cidr              = var.allowed_ssh_cidr
  labels                        = var.labels
}

module "gke" {
  source = "./modules/gke"

  project_id                    = var.project_id
  region                        = var.region
  cluster_name                  = var.cluster_name
  network_name                  = module.networking.vpc_name
  subnet_name                   = module.networking.subnet_name
  pods_secondary_range_name     = var.pods_secondary_range_name
  services_secondary_range_name = var.services_secondary_range_name
  
  gke_version              = var.gke_version
  enable_network_policy    = var.enable_network_policy
  enable_logging           = var.enable_logging
  enable_monitoring        = var.enable_monitoring
  
  node_pool_name           = var.node_pool_name
  initial_node_count       = var.initial_node_count
  min_node_count           = var.min_node_count
  max_node_count           = var.max_node_count
  machine_type             = var.machine_type
  disk_size_gb             = var.disk_size_gb
  enable_preemptible_nodes = var.enable_preemptible_nodes
  
  labels = var.labels

  depends_on = [module.networking]
}
