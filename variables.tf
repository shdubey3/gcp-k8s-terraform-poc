# ── Required (no default) ─────────────────────────────────────────────────────
# Set via environment variables before running terraform:
#   source setenv.sh

variable "project_id" {
  description = "GCP project ID. Set via: export MY_PROJECT=your-project-id && source setenv.sh"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "project_id must not be empty."
  }
}

variable "master_authorized_cidr" {
  description = "CIDR allowed to reach the Kubernetes API server. Set via: export MY_CIDR=$(curl -s ifconfig.me)/32 && source setenv.sh"
  type        = string
}

# ── Cluster ────────────────────────────────────────────────────────────────────

variable "cluster" {
  description = "GKE cluster settings"
  type = object({
    name              = optional(string, "andromeda")
    region            = optional(string, "us-west1")
    gke_version       = optional(string, "1.34.4-gke.1130000")
    release_channel   = optional(string, "STABLE")
    node_locations    = optional(list(string), ["us-west1-a"])
    max_pods_per_node = optional(number, 110)
  })
  default = {}
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "network" {
  description = "VPC and subnet settings. CIDRs can be overridden via TF_VAR_network (JSON) if needed."
  type = object({
    vpc_name            = optional(string, "main-network")
    subnet_name         = optional(string, "main-subnet")
    vpc_cidr            = optional(string, "10.0.0.0/16")
    subnet_cidr         = optional(string, "10.0.1.0/24")
    pods_range_name     = optional(string, "main-pods")
    pods_cidr           = optional(string, "10.1.0.0/16")
    services_range_name = optional(string, "main-services")
    services_cidr       = optional(string, "10.2.0.0/16")
    allowed_ssh_cidr    = optional(string, "0.0.0.0/0")
  })
  default = {}
}

# ── Node Pool ─────────────────────────────────────────────────────────────────

variable "node_pool" {
  description = "Default node pool settings"
  type = object({
    name          = optional(string, "default-pool")
    machine_type  = optional(string, "e2-medium")
    disk_size_gb  = optional(number, 100)
    disk_type     = optional(string, "pd-balanced")
    image_type    = optional(string, "COS_CONTAINERD")
    initial_count = optional(number, 3)
    min_count     = optional(number, 3)
    max_count     = optional(number, 10)
  })
  default = {}
}

# ── Node Auto-Provisioning ────────────────────────────────────────────────────

variable "autoprovisioning" {
  description = "Node Auto-Provisioning (cluster autoscaler) resource limits"
  type = object({
    min_cpu    = optional(number, 1)
    max_cpu    = optional(number, 10)
    min_memory = optional(number, 1)
    max_memory = optional(number, 64)
    locations  = optional(list(string), ["us-west1-a"])
  })
  default = {}
}

# ── Labels ────────────────────────────────────────────────────────────────────

variable "labels" {
  description = "Common labels applied to all resources"
  type        = map(string)
  default = {
    environment = "poc"
    managed_by  = "terraform"
  }
}
