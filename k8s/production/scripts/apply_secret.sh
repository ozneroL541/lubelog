#!/usr/bin/env bash
# Merges the plain Secret template with sops-decrypted values and applies it.
# Usage: SOPS_AGE_KEY_FILE=/path/to/key.txt ./apply-secret.sh
set -euo pipefail

TEMPLATE="02-postgres-secret.yaml"
VALUES_ENC="postgres-secrets.yaml"

TMP_VALUES="$(mktemp)"
trap 'rm -f "$TMP_VALUES"' EXIT

sops -d "$VALUES_ENC" > "$TMP_VALUES"

yq eval ".stringData = load(\"$TMP_VALUES\")" "$TEMPLATE"
# ^ swap the last line for:  | kubectl apply -f -