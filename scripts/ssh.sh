#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_HOST="${1:-openclaw-rpi5.local}"
TARGET_USER="nixos"
KEY_FILE="${SCRIPT_DIR}/../id_ed25519_rpi5"

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first to set up SSH authentication."
  exit 1
fi

exec ssh -i "${KEY_FILE}" -o StrictHostKeyChecking=accept-new "${TARGET_USER}@${TARGET_HOST}"
