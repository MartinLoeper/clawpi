#!/usr/bin/env bash
set -euo pipefail

IMAGE=$(find result/ -name '*.img' -o -name '*.img.zst' 2>/dev/null | head -1)

if [ -z "$IMAGE" ]; then
  echo "No image found in result/. Run ./build.sh first."
  exit 1
fi

REAL_IMAGE=$(realpath "$IMAGE")
echo "Flashing: $REAL_IMAGE"
echo ""

sudo caligula burn "$REAL_IMAGE"
