#!/bin/bash

set -e

cd /distro/imp

truncate -s 200MB boot.img
mkfs boot.img
mkdir mnt
mount boot.img mnt
extlinux -i mnt
mv bin lib64 linuxrc sbin usr mnt
cd mnt
mkdir var etc root tmp dev proc
cd ..
umount mnt

exit 0