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

TOKEN=$(ssh -i "${KEY_FILE}" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new \
  "${TARGET_USER}@${TARGET_HOST}" \
  "sudo cat /var/lib/kiosk/.openclaw/gateway-token.env 2>/dev/null | sed 's/^OPENCLAW_GATEWAY_TOKEN=//'")

if [ -z "${TOKEN}" ]; then
  echo "Error: Gateway token not found. Has the kiosk specialisation been activated?"
  exit 1
fi

echo ""
echo "  OpenClaw Gateway Token"
echo "  ======================"
echo ""
echo "  ${TOKEN}"
echo ""
echo "  Dashboard: http://${TARGET_HOST}:18789?token=${TOKEN}"
echo ""
