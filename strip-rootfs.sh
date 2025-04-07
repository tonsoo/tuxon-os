#!/bin/bash
set -e

ROOTFS=${1:-"./src"}

if [ ! -d "$ROOTFS" ]; then
  echo "❌ Root filesystem directory not found: $ROOTFS"
  exit 1
fi

echo "🧹 Cleaning up unnecessary files in: $ROOTFS"

# Remove APT cache
rm -rf "$ROOTFS/var/lib/apt/lists/"*

# Remove docs, man pages, and other unneeded data
rm -rf "$ROOTFS/usr/share/doc/"*
rm -rf "$ROOTFS/usr/share/info/"*
rm -rf "$ROOTFS/usr/share/lintian/"*
rm -rf "$ROOTFS/usr/share/bug/"*
rm -rf "$ROOTFS/usr/share/man/"*

# Keep only English locale
find "$ROOTFS/usr/share/locale" -mindepth 1 -maxdepth 1 ! -name "en*" -exec rm -rf {} +
rm -rf "$ROOTFS/usr/share/locale/*/LC_MESSAGES/*.mo"

# Remove any leftover logs, caches, crash reports
rm -rf "$ROOTFS/var/cache/"*
rm -rf "$ROOTFS/var/log/"*
rm -rf "$ROOTFS/var/tmp/"*
rm -rf "$ROOTFS/tmp/"*

# Remove unused kernel drivers (careful, keep if you need real hardware support)
find "$ROOTFS/lib/modules/" -type d -name "drivers" -exec rm -rf {} +

# Remove unused systemd services, udev rules (optional)
rm -rf "$ROOTFS/etc/systemd/system/multi-user.target.wants/"*
rm -rf "$ROOTFS/etc/systemd/system/sysinit.target.wants/"*
rm -rf "$ROOTFS/etc/udev/rules.d/"*

# Remove Python bytecode if any
find "$ROOTFS" -name "*.pyc" -delete

# Zero free space (optional: good for final compression)
# dd if=/dev/zero of="$ROOTFS/zero.fill" bs=1M || true
# rm -f "$ROOTFS/zero.fill"

echo "✅ Root filesystem stripped successfully."
