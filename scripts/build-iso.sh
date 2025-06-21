#!/bin/bash

set -e

OUT="$1"
mkdir -p /build/iso/boot/grub

cp /build/vmlinuz iso/boot/
cp /build/initrd.img /build/iso/boot/

cat > /build/iso/boot/grub/grub.cfg <<'EOF'
set default=0
set timeout=5
menuentry "My Linux Distro" {
    linux /boot/vmlinuz quiet
    initrd /boot/initrd.img
}
EOF

grub-mkrescue -o "$OUT" /build/iso/
echo "✅ ISO created at $OUT"
