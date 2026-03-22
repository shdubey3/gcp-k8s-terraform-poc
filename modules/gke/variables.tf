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

variable "network_self_link" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "subnet_self_link" {
  description = "Self-link of the subnet"
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
  description = "Kubernetes version for the cluster (e.g. 1.34.4-gke.1130000)"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE, UNSPECIFIED)"
  type        = string
  default     = "STABLE"
}

variable "master_authorized_cidr" {
  description = "CIDR allowed to reach the Kubernetes API server (set via TF_VAR_master_authorized_cidr)"
  type        = string
}

variable "node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default-pool"
}

variable "initial_node_count" {
  description = "Initial number of nodes per zone"
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
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Disk type for nodes (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-balanced"
}

variable "image_type" {
  description = "Node image type"
  type        = string
  default     = "COS_CONTAINERD"
}

variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 110
}

variable "node_locations" {
  description = "List of zones for node placement within the region"
  type        = list(string)
  default     = ["us-west1-a"]
}

variable "autoprovisioning_min_cpu" {
  description = "Minimum CPU cores for Node Auto-Provisioning"
  type        = number
  default     = 1
}

variable "autoprovisioning_max_cpu" {
  description = "Maximum CPU cores for Node Auto-Provisioning"
  type        = number
  default     = 10
}

variable "autoprovisioning_min_memory" {
  description = "Minimum memory (GB) for Node Auto-Provisioning"
  type        = number
  default     = 1
}

variable "autoprovisioning_max_memory" {
  description = "Maximum memory (GB) for Node Auto-Provisioning"
  type        = number
  default     = 64
}

variable "autoprovisioning_locations" {
  description = "Zones where Node Auto-Provisioning can create nodes"
  type        = list(string)
  default     = ["us-west1-a"]
}

variable "labels" {
  description = "Common labels to apply to resources"
  type        = map(string)
  default     = {}
}
