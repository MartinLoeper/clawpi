#!/usr/bin/env bash
# Approve a Telegram pairing request on the Pi.
#
# Usage: ./scripts/approve-telegram.sh <PAIRING_CODE> [host]
#
# When dmPolicy is "pairing" (default), new Telegram users must be approved.
# The bot will reply with a pairing code (e.g. "RGQB2TEX") — run this script
# with that code to grant access.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAIRING_CODE="${1:-}"
TARGET_HOST="${2:-openclaw-rpi5.local}"
KEY_FILE="${SCRIPT_DIR}/../id_ed25519_rpi5"

if [ -z "${PAIRING_CODE}" ]; then
  echo "Usage: ./scripts/approve-telegram.sh <PAIRING_CODE> [host]"
  echo ""
  echo "The pairing code is shown by the bot when a new user messages it."
  exit 1
fi

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first."
  exit 1
fi

SSH="ssh -i ${KEY_FILE} -o StrictHostKeyChecking=accept-new nixos@${TARGET_HOST}"

echo "Approving Telegram pairing code ${PAIRING_CODE} on ${TARGET_HOST}..."
${SSH} "sudo -u kiosk HOME=/var/lib/kiosk openclaw pairing approve telegram ${PAIRING_CODE}"
echo "Done. The user should now be able to chat with the bot."
