#!/usr/bin/env bash
# Encrypts the Kubernetes Secret template using sops and the age keypair.
# Set exit on error, treat unset variables as an error, and fail on pipe errors
set -euo pipefail
# Set the path to the SOPS age key file
SOPS_AGE_KEY_FILE="k8s/production/secrets/key.txt"
# Directory containing the Kubernetes files
DIR="k8s/production/"
# Kubernetes Secret template file
TEMPLATE=""$DIR"02-secrets.yaml"
BASENAME="$(basename "${TEMPLATE}" .yaml)"
OUTPUT_FILE="$(dirname "${TEMPLATE}")/${BASENAME}.enc.yaml"
# Encrypt the Kubernetes Secret template using sops and the age keypair
SOPS_CONFIG=k8s/production/.sops sops --encrypt "${TEMPLATE}" > "${OUTPUT_FILE}"

# Debugging purposes: this will print the unredacted content in order to make a debug log check just in case.
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
./k8s/scripts/decrypt_secret.sh ./k8s/production/02-secrets.enc.yaml
