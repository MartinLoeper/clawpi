#!/usr/bin/env bash
# Provision a Telegram bot token and optional group allowlist on the Pi.
#
# Usage: ./scripts/provision-telegram.sh [host] [key_file]
#
# This script:
# 1. Prompts for the bot token (from @BotFather)
# 2. Writes it to /var/lib/clawpi/telegram-bot-token on the Pi
# 3. Optionally prompts for group IDs to allowlist
# 4. Writes them to /var/lib/clawpi/telegram-allowed-groups on the Pi
# 5. Prints the next steps
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_HOST="${1:-openclaw-rpi5.local}"
KEY_FILE="${2:-${SCRIPT_DIR}/../id_ed25519_rpi5}"
TOKEN_PATH="/var/lib/clawpi/telegram-bot-token"
GROUP_ALLOW_PATH="/var/lib/clawpi/telegram-allowed-groups"

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first."
  exit 1
fi

SSH="ssh -i ${KEY_FILE} -o StrictHostKeyChecking=accept-new nixos@${TARGET_HOST}"

echo "=== ClawPi Telegram Bot Provisioning ==="
echo ""
echo "Create a bot via @BotFather on Telegram first."
echo "Send /newbot, follow the prompts, and copy the token."
echo ""
read -rp "Paste your bot token: " BOT_TOKEN

if [ -z "${BOT_TOKEN}" ]; then
  echo "Error: empty token"
  exit 1
fi

echo ""
echo "Writing token to ${TARGET_HOST}:${TOKEN_PATH}..."
${SSH} "sudo mkdir -p /var/lib/clawpi && echo -n '${BOT_TOKEN}' | sudo tee ${TOKEN_PATH} > /dev/null && sudo chown kiosk:kiosk ${TOKEN_PATH} && sudo chmod 600 ${TOKEN_PATH}"
echo "Done."

echo ""
echo "=== Group Configuration ==="
echo ""
echo "The bot uses groupPolicy = \"open\" so any member in a configured group"
echo "can message it. To restrict WHICH groups the bot responds in, add group"
echo "IDs here. Get a group ID by adding @RawDataBot to the group — it will"
echo "print the chat ID (e.g. -1001234567890)."
echo ""
read -rp "Enter group IDs (space-separated, or leave empty to skip): " GROUP_IDS

if [ -n "${GROUP_IDS}" ]; then
  # Convert space-separated IDs to newline-separated
  GROUP_IDS_NL="$(echo "${GROUP_IDS}" | tr ' ' '\n')"
  echo ""
  echo "Writing group list to ${TARGET_HOST}:${GROUP_ALLOW_PATH}..."
  ${SSH} "echo '${GROUP_IDS_NL}' | sudo tee ${GROUP_ALLOW_PATH} > /dev/null && sudo chown kiosk:kiosk ${GROUP_ALLOW_PATH} && sudo chmod 600 ${GROUP_ALLOW_PATH}"
  echo "Done."
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Deploy: FLAKE_ATTR=rpi5-telegram ./scripts/deploy.sh ${TARGET_HOST}"
echo ""
echo "2. Verify: ssh nixos@${TARGET_HOST} sudo tail -50 /tmp/openclaw/openclaw-gateway.log"
echo ""
echo "3. Send a message to your bot on Telegram. With the default dmPolicy"
echo "   (\"pairing\"), the bot will reply with a pairing code. Approve it:"
echo ""
echo "   ./scripts/approve-telegram.sh <PAIRING_CODE> ${TARGET_HOST}"
