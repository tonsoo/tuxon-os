#!/bin/bash

set -e

TARGET=/build/rootfs

echo "Pre-debootstrap disk usage:"
du -sh /build
df -h /build

# Ensure TARGET directory is empty and clean before debootstrap starts
rm -rf "$TARGET"
mkdir -p "$TARGET"

debootstrap --arch amd64 focal "$TARGET" http://mirrors.kernel.org/ubuntu/

if [ $? -ne 0 ]; then
  echo "❌ debootstrap failed. Examining logs and disk space again:"
  du -sh /build/rootfs
  df -h /build
  exit 1
fi

mkdir -p "$TARGET/etc" "$TARGET/usr"

cp -r filesystem/etc "$TARGET/"
cp -r filesystem/usr "$TARGET/"

# Run commands inside the chrooted environment
chroot "$TARGET" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt update"

# ADD initramfs-tools HERE!
chroot "$TARGET" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y bash vim initramfs-tools"
#                                                               ^^^^^^^^^^^^^^^^ new

chroot "$TARGET" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt clean"

echo "✅ RootFS setup complete in $TARGET"