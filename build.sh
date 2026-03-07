#!/usr/bin/env bash
set -euo pipefail

echo "Building NixOS SD image for Raspberry Pi 5..."
nix build .#installerImages.rpi5 -L --show-trace "$@"

echo ""
echo "Build complete! Image location:"
ls -lh result/sd-image/*.img* 2>/dev/null || ls -lh result/*.img* 2>/dev/null || echo "Check ./result/ for the output image."
