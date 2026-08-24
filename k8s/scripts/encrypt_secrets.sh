#!/usr/bin/env bash
# Encrypts the Kubernetes Secret template using sops and the age keypair.
# Set exit on error, treat unset variables as an error, and fail on pipe errors
set -euo pipefail
# Set the path to the SOPS age key file
SOPS_AGE_KEY_FILE="production/secrets/key.txt"
# Directory containing the Kubernetes files
DIR="production/"
# Kubernetes Secret template file
TEMPLATE=""$DIR"02-secrets.yaml"
BASENAME="$(basename "${TEMPLATE}" .yaml)"
OUTPUT_FILE="$(dirname "${TEMPLATE}")/${BASENAME}.enc.yaml"
# Encrypt the Kubernetes Secret template using sops and the age keypair
sops --encrypt "${TEMPLATE}" > "${OUTPUT_FILE}"
