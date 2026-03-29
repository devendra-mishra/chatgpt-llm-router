#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -k "${ROOT_DIR}/deployments"

echo "Deployment applied from ${ROOT_DIR}/deployments"
