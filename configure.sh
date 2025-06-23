#!/bin/bash

CUSTOM_DISTRO_NAME="TuxonOs"
CUSTOM_HOSTNAME="tuxon.com.br"

export LB_BINARY_IMAGES=iso-hybrid

lb config \
  --architecture amd64 \
  --distribution noble \
  --linux-flavours generic \
  --bootloader grub-efi \
  --iso-publisher "TuxonOs Team" \
  --iso-application "TuxonOs Live CD" \
  --parent-archive-areas "main universe multiverse restricted" \
  --parent-mirror-bootstrap http://archive.ubuntu.com/ubuntu/ \
  --parent-mirror-chroot http://archive.ubuntu.com/ubuntu/ \
  --parent-mirror-binary http://archive.ubuntu.com/ubuntu/ \
  --parent-mirror-binary-security http://security.ubuntu.com/ubuntu/ \
  --parent-mirror-binary-backports http://archive.ubuntu.com/ubuntu/ \
  --debian-installer false \
  --binary-images iso-hybrid
