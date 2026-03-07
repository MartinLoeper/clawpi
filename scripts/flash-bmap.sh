#!/usr/bin/env bash
set -euo pipefail

IMAGE=$(find result/ -name '*.img' -o -name '*.img.zst' 2>/dev/null | head -1)

if [ -z "$IMAGE" ]; then
  echo "No image found in result/. Run ./build.sh first."
  exit 1
fi

REAL_IMAGE=$(realpath "$IMAGE")

if [ -z "${1:-}" ]; then
  echo "Usage: $0 /dev/sdX"
  echo ""
  echo "Image: $REAL_IMAGE"
  echo ""
  echo "Available disks:"
  lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -v loop
  exit 1
fi

DEST="$1"

unmount_device() {
  MOUNTS=$(lsblk -ln -o MOUNTPOINTS "$DEST" | grep -v '^$' || true)
  if [ -n "$MOUNTS" ]; then
    echo "Unmounting partitions on $DEST..."
    for mp in $MOUNTS; do
      sudo umount "$mp"
    done
  fi
}

unmount_device

echo "Flashing: $REAL_IMAGE -> $DEST"
echo ""

sudo bmaptool copy --nobmap "$REAL_IMAGE" "$DEST"

echo ""
echo "Syncing..."
sync

# Unmount any auto-mounted partitions after flash
unmount_device

echo "Done! Safe to remove the device."
