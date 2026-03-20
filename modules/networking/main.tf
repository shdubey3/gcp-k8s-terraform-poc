# Networking Module - VPC, Subnet, and Firewall Rules

# Create a custom VPC network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  description = "Custom VPC for GKE cluster"
}

# Create a subnet with secondary IP ranges (for pods and services)
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr

  description = "Custom subnet for GKE cluster with secondary ranges"

  # Secondary IP range for Kubernetes Pods
  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }

  # Secondary IP range for Kubernetes Services
  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_cidr
  }

  private_ip_google_access = true
  enable_flow_logs         = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  labels = var.labels
}

# Firewall rule: Allow SSH from specified CIDR
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vpc_name}-allow-ssh"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["gke-node"]

  description = "Allow SSH access from specified CIDR"
}

# Firewall rule: Allow HTTP and HTTPS from internet
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.vpc_name}-allow-http-https"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node"]

  description = "Allow HTTP and HTTPS access from the internet"
}

# Firewall rule: Allow internal VPC communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]

  description = "Allow all internal communication within VPC"
}

# Optional: Allow node-to-node communication (GKE specific)
resource "google_compute_firewall" "allow_gke_node_communication" {
  name    = "${var.vpc_name}-allow-gke-node-comm"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["gke-node"]
  target_tags = ["gke-node"]

  description = "Allow GKE nodes to communicate with each other"
}

# Firewall rule: Allow health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.vpc_name}-allow-health-checks"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
  target_tags = ["gke-node"]

  description = "Allow GCP health checks"
}
