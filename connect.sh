#!/usr/bin/env bash
# connect.sh — Configure kubectl to access the GKE cluster.
# Usage:
#   source setenv.sh   # ensure TF_VAR_project_id is set
#   bash connect.sh
#
# What it does:
#   1. Reads cluster name, region and project from Terraform outputs
#   2. Runs gcloud container clusters get-credentials
#   3. Verifies connectivity with kubectl cluster-info

set -euo pipefail

# ── Resolve project ID ────────────────────────────────────────────────────────
PROJECT_ID="${TF_VAR_project_id:-${MY_PROJECT:-}}"
if [[ -z "${PROJECT_ID}" ]]; then
  echo "ERROR: project ID not set. Run: source setenv.sh" >&2
  exit 1
fi

# ── Read cluster name and region from Terraform state ────────────────────────
echo "Reading cluster info from Terraform state..."
CLUSTER_NAME=$(tofu output -raw kubernetes_cluster_name 2>/dev/null || terraform output -raw kubernetes_cluster_name 2>/dev/null || echo "")
REGION=$(tofu output -raw region 2>/dev/null || terraform output -raw region 2>/dev/null || echo "")

if [[ -z "${CLUSTER_NAME}" || -z "${REGION}" ]]; then
  echo "ERROR: Could not read Terraform outputs. Has 'tofu apply' been run?" >&2
  echo "       Run: tofu apply" >&2
  exit 1
fi

# ── Configure kubectl ─────────────────────────────────────────────────────────
CMD="gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}"
echo ""
echo "Running: ${CMD}"
eval "${CMD}"

# ── Verify connectivity ───────────────────────────────────────────────────────
echo ""
echo "Verifying cluster connectivity..."
kubectl cluster-info
echo ""
echo "Current context: $(kubectl config current-context)"
echo ""
echo "Nodes:"
kubectl get nodes -o wide
