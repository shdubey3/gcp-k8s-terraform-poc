# GKE Terraform – Environment Variable Reference

## Quick Start

```bash
# 1. Set your project and (optionally) your IP
export MY_PROJECT="your-gcp-project-id"
export MY_CIDR="$(curl -s ifconfig.me)/32"   # optional – auto-detected

# 2. Inject into Terraform
source setenv.sh

# 3. Deploy
terraform init
terraform plan
terraform apply
```

That's it. Everything else uses sensible defaults from `variables.tf`.

---

## How It Works

`setenv.sh` translates the two shell variables Terraform needs into the
`TF_VAR_*` format that Terraform reads automatically:

| You set | Becomes | Terraform variable |
|---|---|---|
| `MY_PROJECT` | `TF_VAR_project_id` | `var.project_id` |
| `MY_CIDR` | `TF_VAR_master_authorized_cidr` | `var.master_authorized_cidr` |

All other configuration lives in grouped object variables with defaults —
no sprawling variable list to manage.

---

## Overriding Defaults

All cluster, network, node-pool, and autoprovisioning settings are grouped
into objects with built-in defaults. Override any field via `terraform.tfvars`
(see `terraform.tfvars.example`) or via `TF_VAR_*` JSON:

```bash
# Override individual object fields via JSON env var
export TF_VAR_cluster='{"name":"my-cluster","region":"us-east1"}'
export TF_VAR_node_pool='{"machine_type":"e2-standard-4","min_count":2,"max_count":8}'
export TF_VAR_network='{"vpc_cidr":"10.10.0.0/16","subnet_cidr":"10.10.1.0/24"}'
source setenv.sh && terraform apply
```

Or edit `terraform.tfvars`:
```hcl
cluster = {
  name   = "my-cluster"
  region = "us-east1"
}
node_pool = {
  machine_type = "e2-standard-4"
}
```

---

## Variable Reference

### Required (no default)

| Shell var | `TF_VAR_*` | Description |
|---|---|---|
| `MY_PROJECT` | `TF_VAR_project_id` | GCP project ID |
| `MY_CIDR` | `TF_VAR_master_authorized_cidr` | CIDR for Kubernetes API access |

### `cluster` object defaults

| Field | Default | Description |
|---|---|---|
| `name` | `andromeda` | Cluster name |
| `region` | `us-west1` | GCP region |
| `gke_version` | `1.34.4-gke.1130000` | Kubernetes version |
| `release_channel` | `STABLE` | GKE release channel |
| `node_locations` | `["us-west1-a"]` | Node zones |
| `max_pods_per_node` | `110` | Max pods per node |

### `network` object defaults

| Field | Default | Description |
|---|---|---|
| `vpc_name` | `main-network` | VPC name |
| `subnet_name` | `main-subnet` | Subnet name |
| `vpc_cidr` | `10.0.0.0/16` | VPC primary range |
| `subnet_cidr` | `10.0.1.0/24` | Node subnet range |
| `pods_range_name` | `main-pods` | Pods secondary range name |
| `pods_cidr` | `10.1.0.0/16` | Pods CIDR |
| `services_range_name` | `main-services` | Services secondary range name |
| `services_cidr` | `10.2.0.0/16` | Services CIDR |
| `allowed_ssh_cidr` | `0.0.0.0/0` | SSH firewall source CIDR |

### `node_pool` object defaults

| Field | Default | Description |
|---|---|---|
| `name` | `default-pool` | Node pool name |
| `machine_type` | `e2-medium` | VM machine type |
| `disk_size_gb` | `100` | Boot disk size |
| `disk_type` | `pd-balanced` | Boot disk type |
| `image_type` | `COS_CONTAINERD` | Node OS image |
| `initial_count` | `3` | Initial nodes |
| `min_count` | `3` | Autoscaling min |
| `max_count` | `10` | Autoscaling max |

### `autoprovisioning` object defaults

| Field | Default | Description |
|---|---|---|
| `min_cpu` | `1` | Min CPU for NAP |
| `max_cpu` | `10` | Max CPU for NAP |
| `min_memory` | `1` | Min memory (GB) for NAP |
| `max_memory` | `64` | Max memory (GB) for NAP |
| `locations` | `["us-west1-a"]` | NAP allowed zones |

---

## Security Notes

- **Never commit** `service-account-key.json`, `.access_token`, or any file
  containing a real project ID or CIDR. They are in `.gitignore`.
- `terraform.tfvars` is gitignored. Only `terraform.tfvars.example` is tracked.
- Use `setenv.sh` for secrets — it exports them into the current shell session
  only and is never stored on disk with real values.
