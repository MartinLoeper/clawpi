#!/usr/bin/env bash
# Provision an ElevenLabs API key on the Pi for high-quality TTS.
#
# Usage: ./scripts/provision-elevenlabs.sh [host]
#
# This script:
# 1. Prompts for the ElevenLabs API key (from https://elevenlabs.io/app/settings/api-keys)
# 2. Writes it to /var/lib/clawpi/elevenlabs-api-key on the Pi
# 3. Prints the next steps
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_HOST="${1:-openclaw-rpi5.local}"
KEY_FILE="${SCRIPT_DIR}/../id_ed25519_rpi5"
API_KEY_PATH="/var/lib/clawpi/elevenlabs-api-key"

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first."
  exit 1
fi

SSH="ssh -i ${KEY_FILE} -o StrictHostKeyChecking=accept-new nixos@${TARGET_HOST}"

echo "=== ClawPi ElevenLabs API Key Provisioning ==="
echo ""
echo "Get an API key from https://elevenlabs.io/app/settings/api-keys"
echo ""
read -rp "Paste your ElevenLabs API key: " API_KEY

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
echo "The tts_hq tool is always available in the clawpi-tools plugin."
echo "It reads the API key from ${API_KEY_PATH} at runtime."
echo ""
echo "No deploy needed — just send a message to the agent asking it"
echo "to speak using high-quality TTS."
