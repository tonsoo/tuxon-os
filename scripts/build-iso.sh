#!/bin/bash

set -e

# ISO_NAME is now exported from inner-build.sh
OUT_FILE="$1" # This will receive /build/tuxon-os.iso from inner-build.sh

mkdir -p /build/iso/boot/grub

cp /build/vmlinuz /build/iso/boot/
cp /build/initrd.img /build/iso/boot/

cat > /build/iso/boot/grub/grub.cfg <<EOF
set default=0
set timeout=5
menuentry "TuxonOS (Normal Boot)" {
    linux /boot/vmlinuz root=/dev/sda1 rw
    initrd /boot/initrd.img
}

menuentry "TuxonOS (Verbose Debug)" {
    linux /boot/vmlinuz root=/dev/sda1 rw \
          debug \
          earlyprintk=ttyS0 \
          console=tty0 console=ttyS0,115200 \
          loglevel=7 \
          panic=60

    initrd /boot/initrd.img
}

menuentry "TuxonOS (Initramfs Debug Shell)" {
    linux /boot/vmlinuz root=/dev/sda1 rw \
          debug \
          earlyprintk=ttyS0 \
          console=tty0 console=ttyS0,115200 \
          loglevel=7 \
          break=premount

    initrd /boot/initrd.img
}
EOF

grub-mkrescue -o "$OUT_FILE" /build/iso/
echo "✅ ISO created at $OUT_FILE"