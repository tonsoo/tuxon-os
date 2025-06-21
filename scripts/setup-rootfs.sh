#!/bin/bash

set -e

TARGET=/build/rootfs

echo "Pre-debootstrap disk usage:"
du -sh /build
df -h /build

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

chroot "$TARGET" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt update"
chroot "$TARGET" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt install -y bash vim"
chroot "$TARGET" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt clean"

echo "✅ RootFS setup complete in $TARGET"