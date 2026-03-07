#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_HOST="${1:-openclaw-rpi5.local}"
TARGET_USER="nixos"
FLAKE_ATTR="rpi5"
KEY_FILE="${SCRIPT_DIR}/../id_ed25519_rpi5"

if [ ! -f "${KEY_FILE}" ]; then
  echo "Error: SSH key not found at ${KEY_FILE}"
  echo "Run ./scripts/setup-ssh.sh first to set up SSH authentication."
  exit 1
fi

export NIX_SSHOPTS="-i ${KEY_FILE} -o StrictHostKeyChecking=accept-new"

echo "Resolving ${TARGET_HOST}..."
if ! getent hosts "${TARGET_HOST}" > /dev/null 2>&1; then
  echo "Error: Could not resolve ${TARGET_HOST}"
  echo "Make sure the device is powered on and Avahi (mDNS) is working."
  exit 1
fi

echo "Deploying NixOS to ${TARGET_USER}@${TARGET_HOST}..."
echo "  Flake: .#${FLAKE_ATTR}"
echo ""

nixos-rebuild switch \
  --flake ".#${FLAKE_ATTR}" \
  --target-host "${TARGET_USER}@${TARGET_HOST}" \
  --sudo \
  -L --show-trace \
  "${@:2}"

echo ""
echo "Deploy complete. Verifying mDNS reachability..."
if getent hosts "${TARGET_HOST}" > /dev/null 2>&1; then
  echo "Device reachable at ${TARGET_HOST} ($(getent hosts "${TARGET_HOST}" | awk '{print $1}'))"
else
  echo "Warning: ${TARGET_HOST} not reachable via mDNS after deploy. The device may still be rebooting."
fi
