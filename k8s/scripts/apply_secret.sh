#!/usr/bin/env bash
# 04-apply-secrets.sh
# Decrypts an sops-encrypted secrets manifest straight into `kubectl apply`,
# WITHOUT ever writing plaintext to disk. This is the safest way to deploy
# manually (e.g. before you wire up Flux/Argo native decryption).
#
# Usage:
#   ./04-apply-secrets.sh 02-secrets.enc.yaml
#   ./04-apply-secrets.sh 02-secrets.enc.yaml --context my-cluster

set -euo pipefail

#if [ $# -lt 1 ]; then
#  echo "Usage: $0 <encrypted-secrets-file.enc.yaml> [kubectl-context-args...]"
#  exit 1
#fi

INPUT_FILE="k8s/production/02-secrets.enc.yaml" #"$1"
shift
KUBECTL_ARGS=("--context")  #("$@")

if [ ! -f "${INPUT_FILE}" ]; then
  echo "Error: file not found: ${INPUT_FILE}"
  exit 1
fi

sops --decrypt "${INPUT_FILE}" | kubectl apply "${KUBECTL_ARGS[@]}" -f -
