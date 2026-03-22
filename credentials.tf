# Authentication uses Application Default Credentials (ADC).
# Run: gcloud auth application-default login
#
# setenv.sh automatically sets GOOGLE_APPLICATION_CREDENTIALS to
#   ~/.config/gcloud/application_default_credentials.json
# which carries full project IAM write scope (required for setIamPolicy on destroy).
#
# If you need to use a service account key instead, place it at:
#   ~/.gcp/keys/service-account-key.json
# and set USE_SA_KEY=1 before sourcing setenv.sh:
#   export USE_SA_KEY=1 && source setenv.sh
#
# NOTE: Service account keys must have roles/resourcemanager.projectIamAdmin
# (or roles/owner) to manage project-level IAM policies.
# (Never place key files inside the project directory)
