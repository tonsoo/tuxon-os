#!/bin/bash
set -e

DISTRO="noble"
MIRROR="http://archive.ubuntu.com/ubuntu"
TARGET_DIR="./src"
ISO_DIR="./iso"
HOSTNAME="tuxonos"
USERNAME="tuxuser"
RELEASE=false
MINIMAL=false

# Parse args
for arg in "$@"; do
  case $arg in
    --minimal) MINIMAL=true ;;
    --release) RELEASE=true ; MINIMAL=true ;; # release implies minimal
    --clean) echo "🧹 Cleaning up..."; rm -rf "$TARGET_DIR" "$ISO_DIR"; exit 0 ;;
  esac
done

echo "📦 Bootstrapping $DISTRO into $TARGET_DIR"
sudo debootstrap --variant=minbase "$DISTRO" "$TARGET_DIR" "$MIRROR"

echo "⚙️  Setting up chroot environment..."
sudo cp /etc/resolv.conf "$TARGET_DIR/etc/" # networking
sudo mount --bind /dev "$TARGET_DIR/dev"
sudo mount --bind /proc "$TARGET_DIR/proc"
sudo mount --bind /sys "$TARGET_DIR/sys"

cat <<EOF | sudo chroot "$TARGET_DIR"
set -e
export DEBIAN_FRONTEND=noninteractive

echo "$HOSTNAME" > /etc/hostname

apt update
apt install -y sudo systemd systemd-sysv linux-image-generic

# Create user
useradd -m -s /bin/bash "$USERNAME"
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Optional: Add systemd services
# mkdir -p /etc/systemd/system/multi-user.target.wants
# ln -s /etc/systemd/system/your-service.service ...

apt clean
EOF

# Unmount
sudo umount "$TARGET_DIR/dev" "$TARGET_DIR/proc" "$TARGET_DIR/sys"

# Optional minimal cleanup
if [ "$MINIMAL" = true ]; then
  echo "🧼 Stripping rootfs..."
  ./strip-rootfs.sh "$TARGET_DIR"
fi

# Optional ISO build
if [ "$RELEASE" = true ]; then
  echo "📀 Building bootable ISO..."

  mkdir -p "$ISO_DIR/boot/grub"

  # Copy kernel and initrd
  KERNEL=$(basename "$TARGET_DIR/boot/vmlinuz-"*)
  INITRD=$(basename "$TARGET_DIR/boot/initrd.img-"*)
  cp "$TARGET_DIR/boot/$KERNEL" "$ISO_DIR/boot/vmlinuz"
  cp "$TARGET_DIR/boot/$INITRD" "$ISO_DIR/boot/initrd"

  # Create grub config
  cat > "$ISO_DIR/boot/grub/grub.cfg" <<EOF
set default=0
set timeout=5

menuentry "Tuxon OS" {
    linux /boot/vmlinuz root=/dev/sr0 quiet
    initrd /boot/initrd
}
EOF

  # Build ISO
  grub-mkrescue -o tuxonos.iso "$ISO_DIR" \
    --compress=xz
fi

echo "✅ Build complete!"
