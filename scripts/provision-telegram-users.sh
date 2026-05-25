#!/usr/bin/env bash
# Provision Telegram user allowlist on the Pi.
#
# Usage: ./scripts/provision-telegram-users.sh [host] [key_file]
#
# Users on this list can use slash commands (/new, /model, etc.) in groups.
# Get your Telegram user ID by messaging @userinfobot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_HOST="${1:-openclaw-rpi5.local}"
KEY_FILE="${2:-${SCRIPT_DIR}/../id_ed25519_rpi5}"
USER_ALLOW_PATH="/var/lib/clawpi/telegram-allowed-users"

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first."
  exit 1
fi

SSH="ssh -i ${KEY_FILE} -o StrictHostKeyChecking=accept-new nixos@${TARGET_HOST}"

echo "=== ClawPi Telegram User Allowlist ==="
echo ""
echo "Users on this list can use slash commands (/new, /model, etc.) in groups."
echo "Get your Telegram user ID by messaging @userinfobot."
echo ""
read -rp "Enter user IDs (space-separated): " USER_IDS

if [ -z "${USER_IDS}" ]; then
  echo "Error: no user IDs provided"
  exit 1
fi

USER_IDS_NL="$(echo "${USER_IDS}" | tr ' ' '\n')"
echo ""
echo "Writing user allowlist to ${TARGET_HOST}:${USER_ALLOW_PATH}..."
${SSH} "echo '${USER_IDS_NL}' | sudo tee ${USER_ALLOW_PATH} > /dev/null && sudo chown kiosk:kiosk ${USER_ALLOW_PATH} && sudo chmod 600 ${USER_ALLOW_PATH}"
echo "Done."

echo ""
echo "Restarting openclaw-gateway to pick up changes..."
${SSH} "sudo -u kiosk XDG_RUNTIME_DIR=/run/user/\$(id -u kiosk) systemctl --user restart openclaw-gateway.service"
echo "Done. Slash commands should now work for the listed users."
