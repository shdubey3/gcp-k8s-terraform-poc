# Networking Module Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "pods_secondary_cidr" {
  description = "CIDR block for pods secondary range"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "services_secondary_cidr" {
  description = "CIDR block for services secondary range"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to nodes"
  type        = string
}

variable "labels" {
  description = "Common labels to apply to resources"
  type        = map(string)
}
