#!/bin/bash

set -e

(
  cd /build/rootfs
  find . | cpio -H newc -o | gzip > /build/initrd.img
)
