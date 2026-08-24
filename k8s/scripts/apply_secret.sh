#!/usr/bin/env bash
# Merges the plain Secret template with sops-decrypted values and applies it.
# Usage: SOPS_AGE_KEY_FILE=/path/to/key.txt ./apply-secret.sh

# Set exit on error, treat unset variables as an error, and fail on pipe errors
set -euo pipefail

# Kubernetes Secret template file
TEMPLATE="02-secrets.yaml"
# Secret values file (encrypted with sops)
VALUES_ENC="secrets/secrets.enc.yaml"
# Temporary file to hold decrypted values
TMP_VALUES="$(mktemp)"
# Trap to clean up the temporary file on exit
trap 'rm -f "$TMP_VALUES"' EXIT
# Decrypt the secret values using sops and store them in the temporary file
sops -d "$VALUES_ENC" > "$TMP_VALUES"
# Merge the decrypted values into the template and apply it to Kubernetes
yq eval ".stringData = load(\"$TMP_VALUES\")" "$TEMPLATE"
# ^ swap the last line for:  | kubectl apply -f -
