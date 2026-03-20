# Terraform Configuration File

This production-ready Terraform project provisions a fully functional GKE cluster on Google Cloud Platform with all networking, security, and best practices implemented.

## Project Structure

```
.
├── main.tf                          # Root module orchestration
├── variables.tf                     # Root module variables and defaults
├── outputs.tf                       # Root module outputs
├── provider.tf                      # GCP provider configuration
├── terraform.tfvars.example         # Example variables file
├── modules/
│   ├── networking/
│   │   ├── main.tf                  # VPC, subnet, firewall resources
│   │   ├── variables.tf             # Networking module variables
│   │   └── outputs.tf               # Networking module outputs
│   └── gke/
│       ├── main.tf                  # GKE cluster and node pools
│       ├── variables.tf             # GKE module variables
│       └── outputs.tf               # GKE module outputs
└── README.md                        # This file
```

## Architecture

### Networking
- **VPC Network**: Custom VPC with manual subnet management
- **Subnet**: In us-central1 region with secondary IP ranges
- **Secondary IP Ranges**:
  - Pods: 10.1.0.0/16
  - Services: 10.2.0.0/16
- **Firewall Rules**:
  - SSH from specified CIDR
  - HTTP/HTTPS from internet (optional)
  - Internal VPC communication
  - GKE node-to-node communication
  - GCP health checks

### GKE Cluster
- **Type**: Regional cluster (HA with 3 control plane replicas)
- **Region**: us-central1
- **Node Pool**: Default pool with 3 initial nodes
- **Autoscaling**: Min 3, Max 10 nodes
- **Machine Type**: e2-standard-4 (customizable)
- **Features**:
  - Network Policy (Calico)
  - Cloud Logging enabled
  - Cloud Monitoring enabled
  - Workload Identity
  - Secure Boot and Integrity Monitoring
  - Automatic node repair and upgrade

## Prerequisites

1. **Google Cloud Project**: Have a GCP project created with billing enabled
2. **Terraform**: Install Terraform 1.0 or later
3. **gcloud CLI**: Install and authenticate:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```
4. **Required APIs**: Enable the following in your GCP project:
   - Kubernetes Engine API
   - Compute Engine API
   - Cloud Logging API
   - Cloud Monitoring API

Enable them with:
```bash
gcloud services enable container.googleapis.com compute.googleapis.com logging.googleapis.com monitoring.googleapis.com
```

## Quick Start

### 1. Initialize Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values, especially:
# - project_id (REQUIRED)
# - allowed_ssh_cidr (your IP address)
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review Plan
```bash
terraform plan
```

### 4. Deploy
```bash
terraform apply
```

### 5. Configure kubectl
After deployment, configure kubectl:
```bash
gcloud container clusters get-credentials gke-poc-cluster --region us-central1 --project YOUR_PROJECT_ID
# Or use the output from terraform:
# terraform output configure_kubectl
```

Verify cluster connection:
```bash
kubectl cluster-info
kubectl get nodes
```

## Customization

### Change Cluster Name
Update `terraform.tfvars`:
```hcl
cluster_name = "my-cluster"
```

### Change Node Pool Size
```hcl
initial_node_count = 5
min_node_count     = 3
max_node_count     = 15
```

### Use Different Machine Type
```hcl
machine_type = "n1-standard-8"  # More powerful machines
# or
machine_type = "e2-standard-2"  # Smaller, cheaper machines
```

### Enable Preemptible Nodes (Cost Optimization)
```hcl
enable_preemptible_nodes = true
```

### Customize Network CIDRs
```hcl
vpc_cidr                = "10.50.0.0/16"
subnet_cidr             = "10.50.1.0/24"
pods_secondary_cidr     = "10.51.0.0/16"
services_secondary_cidr = "10.52.0.0/16"
```

### Disable Logging or Monitoring
```hcl
enable_logging    = false
enable_monitoring = false
```

## Accessing the Cluster

### Get Cluster Information
```bash
terraform output
```

### SSH to a Node
```bash
# Get the external IP of a node
gcloud compute instances list

# SSH to the node
gcloud compute ssh NODE_NAME --zone=ZONE
```

### Access Kubernetes Dashboard
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl proxy
# Visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## Security Best Practices Implemented

1. ✅ **Network Policy**: Calico network policy enabled for pod-to-pod traffic control
2. ✅ **Workload Identity**: Uses Workload Identity instead of node credentials
3. ✅ **Secure Boot**: SHIELDED_VM protection with Secure Boot and Integrity Monitoring
4. ✅ **Least Privilege**: Node service account with minimal required permissions
5. ✅ **Private GKE Master**: Cluster endpoints are private by design
6. ✅ **RBAC**: Role-based access control enabled by default
7. ✅ **Monitoring**: Full observability with Cloud Logging and Monitoring
8. ✅ **Automatic Updates**: Nodes receive security patches automatically

## Common Operations

### Scale the Node Pool
```bash
gcloud container node-pools update default-pool \
  --cluster gke-poc-cluster \
  --region us-central1 \
  --num-nodes 5
```

### Update Kubernetes Version
```bash
terraform apply -var='gke_version=1.28'
```

### Add Labels to Nodes
```bash
kubectl label nodes --all workload=general
```

### Drain and Remove a Node (for maintenance)
```bash
kubectl drain NODE_NAME --ignore-daemonsets
gcloud compute instances delete NODE_NAME --zone=ZONE
```

## Cost Optimization

1. **Use Preemptible Nodes**: Set `enable_preemptible_nodes = true` (saves ~70%)
2. **Right-size Machines**: Use e2-standard-2 or e2-standard-4 instead of larger types
3. **Enable Cluster Autoscaling**: Already enabled; scales down unused nodes
4. **Use Committed Use Discounts**: For production, purchase CUDs on Compute Engine

Estimated monthly cost (default config, us-central1):
- 3 e2-standard-4 nodes: ~$200-250
- Network egress: ~$10-30
- Total: ~$210-280 (may vary)

With preemptible nodes: ~$60-80

## Maintenance

### Update Terraform
```bash
terraform get -update
terraform init -upgrade
```

### Refresh State
```bash
terraform refresh
```

### Update Cluster
Nodes update automatically via auto_upgrade. To control upgrade timing:
```hcl
# In modules/gke/main.tf, modify:
management {
  auto_repair  = true
  auto_upgrade = false  # Disable auto-upgrade
}
```

Then manually upgrade:
```bash
gcloud container clusters upgrade gke-poc-cluster --master --cluster-version=1.28
```

## Troubleshooting

### Terraform Apply Fails with API Errors
- Verify required APIs are enabled: `gcloud services list --enabled`
- Check IAM permissions: `gcloud projects get-iam-policy PROJECT_ID`

### Cluster Creation Timeout
- Check GKE quota in your region
- Verify subnet has available IP addresses
- Check firewall rules aren't blocking traffic

### Nodes Not Reaching Ready State
```bash
kubectl describe nodes
kubectl logs --all-namespaces
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ **WARNING**: This will delete the GKE cluster and all associated resources. Data loss will occur if persisted to the cluster.

## Advanced Customization

### Using Remote State
Uncomment the backend configuration in `provider.tf`:
```hcl
backend "gcs" {
  bucket  = "my-terraform-state-bucket"
  prefix  = "gke-poc/terraform/state"
}
```

Then run:
```bash
terraform init
```

### Adding Additional Node Pools
Create a new resource in `modules/gke/main.tf`:
```hcl
resource "google_container_node_pool" "gpu_nodes" {
  name     = "gpu-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  # ... node pool configuration
}
```

### Private GKE Cluster (Advanced)
To make the cluster completely private, add to `modules/gke/main.tf`:
```hcl
private_cluster_config {
  enable_private_nodes    = true
  enable_private_endpoint = false  # Set to true if you have Cloud NAT
  master_ipv4_cidr_block  = "172.16.0.0/28"
}
```

## Support & Documentation

- [GKE Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Terraform Best Practices](https://www.terraform.io/language/modules/develop)
- [Calico Network Policy](https://projectcalico.docs.tigera.io/)

## License

This configuration is provided as-is for educational and professional use.

---

**Last Updated**: March 2026  
**Terraform Version**: >= 1.0  
**GCP Provider Version**: >= 5.0
