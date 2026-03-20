# Main project and region variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "project_id must not be empty."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

# Networking variables
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "gke-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block."
  }
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
  default     = "pods"
}

variable "pods_secondary_cidr" {
  description = "CIDR block for pods secondary range"
  type        = string
  default     = "10.1.0.0/16"
  validation {
    condition     = can(cidrhost(var.pods_secondary_cidr, 0))
    error_message = "pods_secondary_cidr must be a valid CIDR block."
  }
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
  default     = "services"
}

variable "services_secondary_cidr" {
  description = "CIDR block for services secondary range"
  type        = string
  default     = "10.2.0.0/16"
  validation {
    condition     = can(cidrhost(var.services_secondary_cidr, 0))
    error_message = "services_secondary_cidr must be a valid CIDR block."
  }
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to nodes"
  type        = string
  default     = "0.0.0.0/0" # Change to your IP (e.g., "203.0.113.0/32")
}

# GKE Cluster variables
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "gke-poc-cluster"
}

variable "gke_version" {
  description = "Kubernetes version for the GKE cluster (uses latest if not specified)"
  type        = string
  default     = null # null means latest version
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

# Node pool variables
variable "node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default-pool"
}

variable "initial_node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 3
  validation {
    condition     = var.initial_node_count >= 1
    error_message = "initial_node_count must be at least 1."
  }
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 3
  validation {
    condition     = var.min_node_count >= 1
    error_message = "min_node_count must be at least 1."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
  validation {
    condition     = var.max_node_count >= var.min_node_count
    error_message = "max_node_count must be greater than or equal to min_node_count."
  }
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 100
  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb must be at least 10."
  }
}

variable "enable_preemptible_nodes" {
  description = "Use preemptible nodes to reduce costs"
  type        = bool
  default     = false
}

# Labels and tags
variable "environment" {
  description = "Environment identifier"
  type        = string
  default     = "poc"
}

variable "labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    environment = "poc"
    managed_by  = "terraform"
    project     = "gke-poc"
  }
}
