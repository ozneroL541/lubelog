
#!/usr/bin/env bash
# apply_secret.sh
# Decrypts the sops-encrypted secrets manifest straight into `kubectl apply`,
# without ever writing plaintext to disk. Works with zero arguments.
#
# Usage:
#   ./apply_secret.sh                        # applies against current kubectl context
#   K8S_CONTEXT=prod ./apply_secret.sh        # applies against a specific context
#   ./apply_secret.sh k8s/staging/02-secrets.enc.yaml   # override the file
 
set -euo pipefail
 
# Always run relative to the repo root, regardless of cwd.
cd "$(git rev-parse --show-toplevel)"
 
INPUT_FILE="${1:-k8s/production/02-secrets.enc.yaml}"
 
# Optional: set K8S_CONTEXT=some-context to target a non-default cluster.
# Left unset, kubectl just uses whatever context is currently active.
CONTEXT="${K8S_CONTEXT:-}"
KUBECTL_ARGS=()
if [ -n "${CONTEXT}" ]; then
  KUBECTL_ARGS+=(--context "${CONTEXT}")
fi
 
# Default key file location, same convention as decrypt_secret.sh.
DEFAULT_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"
if [ -z "${SOPS_AGE_KEY_FILE:-}" ] && [ -f "${DEFAULT_AGE_KEY_FILE}" ]; then
  export SOPS_AGE_KEY_FILE="${DEFAULT_AGE_KEY_FILE}"
fi
 
if [ ! -f "${INPUT_FILE}" ]; then
  echo "Error: file not found: ${INPUT_FILE}"
  exit 1
fi
# Decrypt the secrets manifest and pipe it directly into kubectl apply, without writing plaintext to disk.
sops --decrypt "${INPUT_FILE}" | kubectl apply "${KUBECTL_ARGS[@]}" -f -
 