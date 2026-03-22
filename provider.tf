terraform {
  required_version = ">= 1.3" # 1.3+ required for optional() with defaults in object variables

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state management
  # backend "gcs" {
  #   bucket  = "your-terraform-state-bucket"
  #   prefix  = "gke-poc/terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.cluster.region
}
