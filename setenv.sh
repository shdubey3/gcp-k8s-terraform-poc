#!/usr/bin/env bash
# setenv.sh — Map shell variables to Terraform env vars.
# Usage:
#   export MY_PROJECT="your-gcp-project-id"
#   export MY_CIDR="$(curl -s ifconfig.me)/32"   # optional – auto-detected
#   source setenv.sh
#   terraform plan / terraform apply

# ── Required ──────────────────────────────────────────────────────────────────
if [[ -z "${MY_PROJECT}" ]]; then
  echo "ERROR: MY_PROJECT is not set. Run: export MY_PROJECT=your-gcp-project-id" >&2
  return 1 2>/dev/null || exit 1
fi
export TF_VAR_project_id="${MY_PROJECT}"

# ── MY_CIDR – auto-detect current public IP if not provided ──────────────────
if [[ -z "${MY_CIDR}" ]]; then
  echo "MY_CIDR not set – detecting your current public IP..."
  MY_CIDR="$(curl -s ifconfig.me)/32"
  if [[ "${MY_CIDR}" == "/32" ]]; then
    echo "ERROR: Could not detect public IP. Set MY_CIDR manually: export MY_CIDR=x.x.x.x/32" >&2
    return 1 2>/dev/null || exit 1
  fi
fi
export TF_VAR_master_authorized_cidr="${MY_CIDR}"

# ── Optional cluster/network overrides ───────────────────────────────────────
# Uncomment and set any of these to override the built-in defaults without
# editing terraform.tfvars:
#
# export TF_VAR_cluster='{"name":"my-cluster","region":"us-west1"}'
# export TF_VAR_node_pool='{"machine_type":"e2-standard-4","min_count":3,"max_count":10}'
# export TF_VAR_network='{"vpc_cidr":"10.10.0.0/16","subnet_cidr":"10.10.1.0/24"}'

# ── Credentials: explicit ADC path wins; SA key is opt-in only ───────────────
# If GOOGLE_APPLICATION_CREDENTIALS is already set in the environment, honour it.
# Otherwise, prefer the ADC file created by `gcloud auth application-default login`
# (includes full project IAM write scope needed for setIamPolicy).
# To use a service account key instead, set USE_SA_KEY=1 before sourcing this file.
ADC_FILE="${HOME}/.config/gcloud/application_default_credentials.json"
SA_KEY="${HOME}/.gcp/keys/service-account-key.json"

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  if [[ "${USE_SA_KEY:-0}" == "1" && -f "${SA_KEY}" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="${SA_KEY}"
  elif [[ -f "${ADC_FILE}" ]]; then
    export GOOGLE_APPLICATION_CREDENTIALS="${ADC_FILE}"
  else
    echo "WARNING: No credentials found. Run: gcloud auth application-default login" >&2
  fi
fi

echo "──────────────────────────────────────────"
echo " TF_VAR_project_id              = ${TF_VAR_project_id}"
echo " TF_VAR_master_authorized_cidr  = ${TF_VAR_master_authorized_cidr}"
if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  echo " GOOGLE_APPLICATION_CREDENTIALS = ${GOOGLE_APPLICATION_CREDENTIALS}"
fi
echo "──────────────────────────────────────────"
echo "Ready. Run: tofu plan"
