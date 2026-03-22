# GKE Module - Creates a regional GKE cluster with node pools

# Service account for node pool
resource "google_service_account" "node_pool_sa" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "Service Account for ${var.cluster_name} Node Pool"
  project      = var.project_id
  description  = "Service account used by GKE nodes"
}

resource "google_project_iam_member" "node_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}

resource "google_project_iam_member" "node_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}

resource "google_project_iam_member" "node_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}

resource "google_project_iam_member" "node_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.node_pool_sa.email}"
}

# Regional GKE cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # Remove default node pool immediately; manage node pools separately
  remove_default_node_pool = true
  initial_node_count       = 1

  # Disable basic auth (--no-enable-basic-auth)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Release channel (--release-channel "stable")
  release_channel {
    channel = var.release_channel
  }

  # Pin to specific GKE version
  min_master_version = var.gke_version

  # Network and subnet (via self-links for explicit referencing)
  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  # Alias IP ranges for pods and services (--enable-ip-alias)
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Default max pods per node (--default-max-pods-per-node "110")
  default_max_pods_per_node = var.max_pods_per_node

  # Node zones (--node-locations "us-west1-a")
  node_locations = var.node_locations

  # Addons: HPA, HttpLoadBalancing, GcePersistentDiskCsiDriver
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # Logging: SYSTEM + WORKLOAD (--logging=SYSTEM,WORKLOAD)
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  # Monitoring: all components from gcloud command
  # --monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,CADVISOR,KUBELET
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "STORAGE",
      "POD",
      "DEPLOYMENT",
      "STATEFULSET",
      "DAEMONSET",
      "HPA",
      "CADVISOR",
      "KUBELET",
    ]
    managed_prometheus {
      enabled = true
    }
  }

  # Cluster autoscaling / Node Auto-Provisioning
  # --enable-autoprovisioning --min-cpu 1 --max-cpu 1 --min-memory 1 --max-memory 1
  cluster_autoscaling {
    enabled = true

    resource_limits {
      resource_type = "cpu"
      minimum       = var.autoprovisioning_min_cpu
      maximum       = var.autoprovisioning_max_cpu
    }

    resource_limits {
      resource_type = "memory"
      minimum       = var.autoprovisioning_min_memory
      maximum       = var.autoprovisioning_max_memory
    }

    autoprovisioning_locations = var.autoprovisioning_locations

    auto_provisioning_defaults {
      service_account = google_service_account.node_pool_sa.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/trace.append",
      ]

      management {
        auto_repair  = true
        auto_upgrade = true
      }

      upgrade_settings {
        max_surge       = 1
        max_unavailable = 0
      }

      shielded_instance_config {
        enable_integrity_monitoring = true
        enable_secure_boot          = true
      }
    }
  }

  # Vertical Pod Autoscaling (--enable-vertical-pod-autoscaling)
  vertical_pod_autoscaling {
    enabled = true
  }

  # Shielded nodes (--enable-shielded-nodes)
  enable_shielded_nodes = true

  # Security posture: standard (--security-posture=standard)
  # Vulnerability scanning: disabled (--workload-vulnerability-scanning=disabled)
  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_DISABLED"
  }

  # Binary Authorization: disabled (--binauthz-evaluation-mode=DISABLED)
  binary_authorization {
    evaluation_mode = "DISABLED"
  }

  # Master authorized networks (--enable-master-authorized-networks --master-authorized-networks $MY_CIDR)
  # No Google public CIDR access (--no-enable-google-cloud-access)
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
    cidr_blocks {
      display_name = "my-ip"
      cidr_block   = var.master_authorized_cidr
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  resource_labels = var.labels
  description     = "Regional GKE cluster - reference configuration"
}

# Separately managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = var.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.initial_node_count

  node_locations = var.node_locations

  # Autoscaling (--enable-autoscaling --min-nodes 3 --max-nodes 10 --location-policy BALANCED)
  autoscaling {
    min_node_count  = var.min_node_count
    max_node_count  = var.max_node_count
    location_policy = "BALANCED"
  }

  # Node management (--enable-autoupgrade --enable-autorepair)
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings (--max-surge-upgrade 1 --max-unavailable-upgrade 0)
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    image_type   = var.image_type

    service_account = google_service_account.node_pool_sa.email

    # Explicit scopes matching the gcloud command (--scopes ...)
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    # Disable legacy metadata endpoints (--metadata disable-legacy-endpoints=true)
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance (--shielded-integrity-monitoring --shielded-secure-boot)
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = merge(var.labels, { node_pool = var.node_pool_name })
    tags   = ["gke-node"]
  }
}
