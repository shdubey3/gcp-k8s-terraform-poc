# GKE Module Outputs

output "cluster_id" {
  description = "The ID (self-link) of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_host" {
  description = "The Kubernetes cluster host (IP address of the Kubernetes master)"
  value       = "https://${google_container_cluster.primary.endpoint}"
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the cluster authentication"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = google_container_cluster.primary.master_version
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "node_pool_id" {
  description = "The ID of the node pool"
  value       = google_container_node_pool.primary_nodes.id
}

output "node_service_account_email" {
  description = "The email of the service account used by nodes"
  value       = google_service_account.node_pool_sa.email
}
