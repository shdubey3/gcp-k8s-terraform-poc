terraform {
  required_version = ">= 1.0"
  
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
  region  = var.region
}
