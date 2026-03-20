# Architecture Overview

## High-Level Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        GCP Project                          │
│                    (us-central1 region)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         VPC Network (10.0.0.0/16)                   │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │  Subnet (10.0.1.0/24) - us-central1          │  │   │
│  │  │                                               │  │   │
│  │  │  ┌────────────────────────────────────────┐  │  │   │
│  │  │  │  GKE Regional Cluster (HA)            │  │  │   │
│  │  │  │  ├─ 3 Control Plane Replicas          │  │  │   │
│  │  │  │  │  (Google-managed)                  │  │  │   │
│  │  │  │  │                                    │  │  │   │
│  │  │  │  ├─ Default Node Pool                 │  │  │   │
│  │  │  │  │  ├─ 3 Initial nodes (e2-std-4)    │  │  │   │
│  │  │  │  │  ├─ Autoscale: 3-10 nodes         │  │  │   │
│  │  │  │  │  ├─ Workload Identity             │  │  │   │
│  │  │  │  │  ├─ Secure Boot enabled           │  │  │   │
│  │  │  │  │  └─ Auto-repair & upgrade         │  │  │   │
│  │  │  │  │                                    │  │  │   │
│  │  │  │  ├─ Networking                        │  │  │   │
│  │  │  │  │  ├─ Pods Range: 10.1.0.0/16       │  │  │   │
│  │  │  │  │  ├─ Services Range: 10.2.0.0/16   │  │  │   │
│  │  │  │  │  ├─ Network Policy (Calico)       │  │  │   │
│  │  │  │  │  └─ Private IP access             │  │  │   │
│  │  │  │  │                                    │  │  │   │
│  │  │  │  └─ Logging & Monitoring              │  │  │   │
│  │  │  │     ├─ Cloud Logging                 │  │  │   │
│  │  │  │     ├─ Cloud Monitoring              │  │  │   │
│  │  │  │     └─ Managed Prometheus            │  │  │   │
│  │  │  └────────────────────────────────────────┘  │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  Firewall Rules Layer:                                      │
│  ├─ SSH (port 22) ← allowed_ssh_cidr                       │
│  ├─ HTTP (port 80) ← 0.0.0.0/0                            │
│  ├─ HTTPS (port 443) ← 0.0.0.0/0                          │
│  ├─ Internal ICMP/TCP/UDP ← VPC (10.0.0.0/16)            │
│  ├─ Node-to-Node ← GKE nodes only                         │
│  └─ Health Checks ← GCP LB (35.191.0.0/16, 130.211.0.0/22)│
│                                                              │
└─────────────────────────────────────────────────────────────┘

External Internet
        ↓
    Load Balancer (L7/L4)
        ↓
    Firewall Rules
        ↓
    GKE Cluster Services (10.2.0.0/16)
        ↓
    Pod Network (10.1.0.0/16)
```

## Module Structure

```
Root Module (main.tf)
├── variables.tf (All input variables)
├── outputs.tf (Root outputs)
├── provider.tf (Terraform & GCP config)
│
├── module "networking"
│   ├── VPC creation
│   ├── Subnet with secondary ranges
│   └── Firewall rules (6 rules total)
│
└── module "gke"
    ├── GKE Regional Cluster
    ├── Node Pool with autoscaling
    ├── Service Account for nodes
    └── IAM roles (logging, monitoring)
```

## Network Flow Architecture

```
Internet Traffic
    ↓
┌─────────────────────────────┐
│   GCP Cloud Load Balancer   │  (HTTP/HTTPS)
└────────────┬────────────────┘
             ↓
┌─────────────────────────────┐
│  Firewall Rules             │  (Allow 80/443)
├─ HTTPS (443) from internet  │
├─ HTTP (80) from internet    │
└────────────┬────────────────┘
             ↓
┌─────────────────────────────┐
│  VPC Network                │  (10.0.0.0/16)
├─ Subnet (10.0.1.0/24)       │
│  ├─ Pods: 10.1.0.0/16       │
│  └─ Services: 10.2.0.0/16   │
└────────────┬────────────────┘
             ↓
┌─────────────────────────────┐
│  GKE Cluster Nodes          │  (3-10 nodes)
├─ Node Network Interface     │
├─ Primary IP: 10.0.1.x/24    │
├─ Pod CIDR: 10.1.x.x/16      │
└────────────┬────────────────┘
             ↓
┌─────────────────────────────┐
│  Kubernetes Services        │  (10.2.0.0/16)
└─────────────────────────────┘
```

## Component Relationships

```
┌──────────────────────────────────────────────────────┐
│            GKE Cluster "gke-poc-cluster"             │
├──────────────────────────────────────────────────────┤
│                                                       │
│  Attached to: VPC Network (gke-vpc)                 │
│  └─ Subnet: gke-subnet (10.0.1.0/24)               │
│     ├─ Pods secondary range: pods (10.1.0.0/16)    │
│     └─ Services secondary range: services (10.2.0.0/16)
│                                                       │
│  Node Pool: default-pool                            │
│  ├─ Nodes: 3 initial (auto-scales to 10)          │
│  ├─ Machine Type: e2-standard-4                    │
│  ├─ Node Service Account: gke-poc-cluster-node-... │
│  │  ├─ Role: roles/logging.logWriter               │
│  │  ├─ Role: roles/monitoring.metricWriter         │
│  │  └─ Role: roles/monitoring.viewer               │
│  └─ Features: Workload Identity, Secure Boot      │
│                                                       │
│  Add-ons:                                           │
│  ├─ HTTP Load Balancing: Enabled                   │
│  ├─ Horizontal Pod Autoscaling: Enabled            │
│  ├─ Network Policy: Enabled (Calico)              │
│  ├─ Cloud Logging: Enabled                         │
│  └─ Cloud Monitoring: Enabled                      │
│                                                       │
└──────────────────────────────────────────────────────┘
```

## Traffic Path Examples

### Inbound: External Client → Service

```
1. Client hits Ingress IP (LoadBalancer)
2. Load Balancer routes to Service Port (10.2.x.x:port)
3. Firewall allows (port 80/443)
4. Service selects Pods (10.1.x.x:port)
5. Pod receives traffic
```

### Internal: Pod → Pod Communication

```
1. Pod A (10.1.1.100) initiates connection
2. Kubernetes DNS resolves service name
3. Service (10.2.0.1) routes to Pod B IPs
4. Network Policy (Calico) enforces rules
5. Pod B (10.1.2.50) receives traffic
6. Return packets follow reverse path
```

### Inter-node Communication

```
1. Pod on Node A (10.0.1.10:kubelet)
2. Needs to reach Pod on Node B (10.0.1.11:kubelet)
3. Firewall "allow-gke-node-communication" allows
4. Tunnel/overlay network routes to destination
5. Pod-to-pod communication established
```

## IAM Permission Model

```
Service Account: gke-poc-cluster-node-pool-sa
├─ Binding: roles/logging.logWriter
│  └─ Can write logs to Cloud Logging
├─ Binding: roles/monitoring.metricWriter
│  └─ Can write metrics to Cloud Monitoring
└─ Binding: roles/monitoring.viewer
   └─ Can read monitoring data

Additionally (implicit):
├─ google.serviceAccounts.getIDToken
│  └─ For Workload Identity (pod to GCP auth)
└─ container.clusterAdmin
   └─ Node-level permissions for kubelet
```

## Data Storage Architecture

```
Node Storage (Ephemeral)
├─ 100 GB local disk (configurable)
├─ Holds: OS, container images, logs
└─ Lost when node terminates

Persistent Storage (Optional - not in this config)
├─ Google Cloud Storage
├─ Persistent Volumes (GCE Persistent Disks)
└─ ConfigMaps & Secrets (backed by etcd)
```

## Logging and Monitoring Flow

```
Cluster Events & Logs
    ↓
Cloud Logging API
    ├─ System component logs (kubelet, apiserver)
    ├─ Pod logs (stdout/stderr)
    └─ Audit logs (if enabled)
    ↓
Cloud Logging Console
    └─ Searchable, filterable interface

Metrics (Prometheus format)
    ↓
Cloud Monitoring API
    ├─ Node metrics (CPU, memory, disk)
    ├─ Pod metrics (via Managed Prometheus)
    ├─ Service metrics
    └─ Custom metrics
    ↓
Cloud Monitoring Dashboard
    └─ Real-time visualization & alerts
```

## Scaling Architecture

### Vertical Scaling (Node Resources)
```
Current: e2-standard-4 (4 vCPU, 16GB RAM per node)
Scale Up To: n1-standard-8 (8 vCPU, 30GB RAM per node)
Run: terraform apply -var='machine_type=n1-standard-8'
```

### Horizontal Scaling (Node Count)
```
Current: 3 nodes min, 10 nodes max
Auto-scales based on:
├─ Pod CPU requests/limits
├─ Pod memory requests/limits
└─ Cluster autoscaler triggers scale-out/in
```

### Pod Autoscaling
```
Kubernetes HPA (Horizontal Pod Autoscaler)
└─ Monitors pod metrics
   ├─ CPU threshold: 80% utilization
   ├─ Memory threshold: 80% utilization
   └─ Scales replicas 1-10 (configurable)
```

## Security Layers

```
Layer 1: Network Level
├─ Firewall Rules (ingress/egress)
├─ Network Policies (Calico)
└─ Private Google Access on subnet

Layer 2: Node Level
├─ Shielded VMs (Secure Boot, Integrity Monitoring)
├─ Service Account with least privilege
└─ Automatic OS patching

Layer 3: Cluster Level
├─ RBAC (Role-based Access Control)
├─ Network Policy enforcement
└─ Audit logging

Layer 4: Pod Level
├─ Pod Security Standards
├─ Container image scanning
└─ Workload Identity for service auth
```

## High Availability Setup

```
Control Plane (Google-managed, highly available)
├─ 3 control plane replicas
├─ Distributed across zones
├─ Automatic failover
└─ Transparent updates

Data Plane (Nodes in node pool)
├─ Initial: 3 nodes (1 per zone)
├─ Autoscaler: 3-10 nodes
├─ Spread across zones
├─ Auto-repair: Replace failed nodes
└─ Auto-upgrade: Security patches applied
```

## Cost Optimization Points

```
1. Machine Selection
   ├─ e2-standard-4: Balanced (default)
   ├─ e2-standard-2: Cheaper, for dev/test
   └─ n1-standard-4: More powerful, pricier

2. Node Count
   ├─ Minimum: Balance cost vs availability
   ├─ Maximum: Prevent runaway costs
   └─ Autoscaling: Scale down unused capacity

3. Preemptible Nodes (70% cheaper)
   ├─ Suitable for: Batch jobs, dev/test
   └─ Not suitable for: Production long-running services

4. Network
   ├─ Egress charges per GB
   └─ Keep traffic internal when possible
```

---

**Produced**: March 2026  
**For**: Production GKE Deployment on GCP
