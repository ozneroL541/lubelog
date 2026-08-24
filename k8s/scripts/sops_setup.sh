#!/usr/bin/env bash
# One time setup script for sops and age keypair. 
# Run this before using sops to encrypt/decrypt secrets.
# Set exit on error, treat unset variables as an error, and fail on pipe errors
set -euo pipefail
# Directory to store the age keypair
AGE_KEY_DIR="${HOME}/.config/sops/age"
# File to store the age keypair
AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"
# Create the directory for the age keypair if it doesn't exist
mkdir -p "${AGE_KEY_DIR}"
# Set permissions to restrict access to the age keypair directory
chmod 700 "${AGE_KEY_DIR}"
# If the age keypair file doesn't exist, generate a new keypair
if [ ! -f "${AGE_KEY_FILE}" ]; then
    # Generate a new age keypair and save it to the specified file
  age-keygen -o "${AGE_KEY_FILE}"
  # Set permissions to restrict access to the age keypair file
  chmod 600 "${AGE_KEY_FILE}"
fi
# Add the public key to .sops.yaml
grep "public key:" "${AGE_KEY_FILE}" | awk '{print $3}' > .sops.yaml
