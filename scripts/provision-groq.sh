#!/usr/bin/env bash
# Provision a Groq API key on the Pi for cloud audio transcription.
#
# Usage: ./scripts/provision-groq.sh [host]
#
# This script:
# 1. Prompts for the Groq API key (from https://console.groq.com/keys)
# 2. Writes it to /var/lib/clawpi/groq-api-key on the Pi
# 3. Prints the next steps (enable in NixOS config, deploy)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_HOST="${1:-openclaw-rpi5.local}"
KEY_FILE="${SCRIPT_DIR}/../id_ed25519_rpi5"
API_KEY_PATH="/var/lib/clawpi/groq-api-key"

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first."
  exit 1
fi

SSH="ssh -i ${KEY_FILE} -o StrictHostKeyChecking=accept-new nixos@${TARGET_HOST}"

echo "=== ClawPi Groq API Key Provisioning ==="
echo ""
echo "Get an API key from https://console.groq.com/keys"
echo ""
read -rp "Paste your Groq API key: " API_KEY

if [ -z "${API_KEY}" ]; then
  echo "Error: empty API key"
  exit 1
fi

echo ""
echo "Writing API key to ${TARGET_HOST}:${API_KEY_PATH}..."
${SSH} "sudo mkdir -p /var/lib/clawpi && echo -n '${API_KEY}' | sudo tee ${API_KEY_PATH} > /dev/null && sudo chown kiosk:kiosk ${API_KEY_PATH} && sudo chmod 600 ${API_KEY_PATH}"
echo "Done."

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Enable Groq transcription in your NixOS config:"
echo ""
echo '   services.clawpi.audio.enable = true;'
echo '   services.clawpi.audio.groq.enable = true;'
echo ""
echo "   Groq uses whisper-large-v3-turbo for near-instant cloud transcription."
echo "   Local whisper.cpp is kept as automatic fallback."
echo ""
echo "2. Deploy: ./scripts/deploy.sh ${TARGET_HOST} --specialisation kiosk"
