#!/bin/bash

set -e

mkdir -p /output
cd /distro/boot

truncate -s 50M boot
mkfs -t fat boot
syslinux boot

mkdir -p m
mount boot m

cat <<EOF > m/syslinux.cfg
DEFAULT linux
LABEL linux
    KERNEL bzImage
    APPEND initrd=init.cpio quiet
EOF
cp bzImage init.cpio m

umount m

cp boot bzImage init.cpio /output

exit 0