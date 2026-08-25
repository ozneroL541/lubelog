#!/usr/bin/env bash
# 03-decrypt-secrets.sh
# Decrypts an sops-encrypted secrets manifest, either to stdout or to a
# file, for local viewing or editing. Requires your age private key to
# be present at ~/.config/sops/age/keys.txt (set by 01-setup-sops.sh).
#
# Usage:
#   ./03-decrypt-secrets.sh 02-secrets.enc.yaml            # prints to stdout
#   ./03-decrypt-secrets.sh 02-secrets.enc.yaml --write     # writes plaintext file next to it

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <encrypted-secrets-file.enc.yaml> [--write]"
  exit 1
fi

INPUT_FILE="$1"
WRITE_FLAG="${2:-}"

if [ ! -f "${INPUT_FILE}" ]; then
  echo "Error: file not found: ${INPUT_FILE}"
  exit 1
fi

if ! command -v sops >/dev/null 2>&1; then
  echo "Error: sops is not installed. Run 01-setup-sops.sh first."
  exit 1
fi

# Use the default age key location unless the caller overrides it.
DEFAULT_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"
if [ -z "${SOPS_AGE_KEY_FILE:-}" ] && [ -f "${DEFAULT_AGE_KEY_FILE}" ]; then
  export SOPS_AGE_KEY_FILE="${DEFAULT_AGE_KEY_FILE}"
fi

if [ ! -f "${DEFAULT_AGE_KEY_FILE}" ]; then
  echo "Error: age key not found at ${DEFAULT_AGE_KEY_FILE}."
  echo "Run ./k8s/scripts/sops_setup.sh to generate one, or restore the original key backup."
  exit 1
fi

if [ "${WRITE_FLAG}" == "--write" ]; then
  OUTPUT_FILE="${INPUT_FILE%.enc.yaml}.yaml"
  sops --decrypt "${INPUT_FILE}" > "${OUTPUT_FILE}"
  echo "Decrypted plaintext written to ${OUTPUT_FILE}"
  echo "Remember: don't commit this file."
else
  sops --decrypt "${INPUT_FILE}"
fi
