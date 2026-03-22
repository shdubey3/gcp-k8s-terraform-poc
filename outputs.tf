# Root module outputs - Exposes key information from submodules

# Networking outputs
output "vpc_id" {
  description = "The ID of the GCP VPC network"
  value       = module.networking.vpc_id
}

output "vpc_name" {
  description = "The name of the GCP VPC network"
  value       = module.networking.vpc_name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = module.networking.subnet_id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = module.networking.subnet_name
}

output "subnet_cidr" {
  description = "The CIDR block of the subnet"
  value       = module.networking.subnet_cidr
}

# GKE Cluster outputs
output "kubernetes_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "kubernetes_cluster_id" {
  description = "The ID (self-link) of the GKE cluster"
  value       = module.gke.cluster_id
}

output "kubernetes_cluster_host" {
  description = "The IP address of the Kubernetes master"
  value       = module.gke.cluster_host
  sensitive   = true
}

output "region" {
  description = "The GCP region where resources are deployed"
  value       = var.cluster.region
}

output "kubernetes_version" {
  description = "The Kubernetes version running on the cluster"
  value       = module.gke.kubernetes_version
}

output "node_pool_name" {
  description = "The name of the default node pool"
  value       = module.gke.node_pool_name
}

# Connection information
output "configure_kubectl" {
  description = "Command to configure kubectl to connect to the GKE cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.cluster.region} --project ${var.project_id}"
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the Kubernetes cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}
