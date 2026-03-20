# GKE Module Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network for the cluster"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for the cluster"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "gke_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = null
}

variable "enable_network_policy" {
  description = "Enable GKE Network Policy"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable GKE cluster logging"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable GKE cluster monitoring"
  type        = bool
  default     = true
}

variable "node_pool_name" {
  description = "Name of the default node pool"
  type        = string
}

variable "initial_node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 100
}

variable "enable_preemptible_nodes" {
  description = "Use preemptible nodes to reduce costs"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Common labels to apply to resources"
  type        = map(string)
}
