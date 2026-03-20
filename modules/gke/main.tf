# GKE Module - Creates a regional GKE cluster with node pools

# Create the regional GKE cluster (3 control plane replicas for HA)
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network and subnet configuration
  network    = var.network_name
  subnetwork = var.subnet_name

  # Kubernetes version
  min_master_version = var.gke_version

  # Cluster networking - use alias IP ranges for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Cluster autoscaling for the whole cluster
  cluster_autoscaling {
    enabled = true

    resource_limits {
      resource_type = "cpu"
      min_limit     = var.min_node_count * 2  # Approximate based on machine type
      max_limit     = var.max_node_count * 4
    }

    resource_limits {
      resource_type = "memory"
      min_limit     = var.min_node_count * 8  # Approximate based on machine type
      max_limit     = var.max_node_count * 16
    }
  }

  # GKE security settings
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = "CALICO"
  }

  # Logging and monitoring
  logging_config {
    enable_components = var.enable_logging ? [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ] : []
  }

  monitoring_config {
    enable_components = var.enable_monitoring ? [
      "SYSTEM_COMPONENTS",
      "WORKLOADS"
    ] : []

    managed_prometheus {
      enabled = var.enable_monitoring
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Database encryption
  database_encryption {
    state    = "ENCRYPTED"
    key_name = "projects/${var.project_id}/locations/${var.region}/keyRings/gke-keyring/cryptoKeys/gke-key"
  }

  # Resource labels
  resource_labels = var.labels

  description = "Production-ready GKE cluster with regional HA"

  # Depends on networking being created
  depends_on = []
}

# Separately managed default node pool with autoscaling
resource "google_container_node_pool" "primary_nodes" {
  name       = var.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.initial_node_count

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    preemptible  = var.enable_preemptible_nodes
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.node_pool_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance options
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Node labels
    labels = merge(
      var.labels,
      {
        node_pool = var.node_pool_name
      }
    )

    # Node tags for firewall rules
    tags = ["gke-node"]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Service account for node pool
resource "google_service_account" "node_pool_sa" {
  account_id   = "${var.cluster_name}-node-pool-sa"
  display_name = "Service Account for ${var.cluster_name} Node Pool"
  project      = var.project_id

  description = "Service account used by GKE nodes"
}

# Grant basic Cloud Logging permissions to the node pool service account
resource "google_project_iam_member" "node_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}

# Grant basic Cloud Monitoring permissions to the node pool service account
resource "google_project_iam_member" "node_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}

# Grant Metric Viewer permissions for Monitoring
resource "google_project_iam_member" "node_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}
