#!/bin/bash

set -e

mkdir -p /output
cd /distro/boot

dd if=/dev/zero of=boot bs=1M count=50
mkdir -p m
mkfs -t fat boot
syslinux boot
mount boot m
cp bzImage init.cpio m
umount m

cp boot /output

exit 0