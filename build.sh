#!/bin/bash
set -e

sudo apt update
sudo apt install -y \
  build-essential grub-pc-bin xorriso mtools \
  qemu-system-x86 git autoconf automake libtool \
  libsdl2-dev libsdl2-mixer-dev libsdl2-net-dev \
  libsdl2-image-dev nasm wget cpio

WORKDIR=$PWD/build
mkdir -p $WORKDIR
cd $WORKDIR

git clone https://github.com/chocolate-doom/chocolate-doom.git
cd chocolate-doom
./autogen.sh
./configure
make -j$(nproc)
cd ..

wget https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad

mkdir -p rootfs/bin rootfs/dev rootfs/proc rootfs/sys

cp chocolate-doom/src/chocolate-doom rootfs/bin/
cp doom1.wad rootfs/bin/

cat > rootfs/init << 'EOF'
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
clear
exec /bin/chocolate-doom -iwad /bin/doom1.wad
EOF

chmod +x rootfs/init

cd rootfs
find . | cpio -o -H newc | gzip > ../initramfs.img
cd ..

wget https://tinycorelinux.net/13.x/x86_64/release/distribution_files/vmlinuz64

mkdir -p iso/boot/grub
cp vmlinuz64 iso/boot/
cp initramfs.img iso/boot/

cat > iso/boot/grub/grub.cfg << 'EOF'
set timeout=0
set default=0
menuentry "DOOM OS" {
    linux /boot/vmlinuz64 quiet
    initrd /boot/initramfs.img
}
EOF

grub-mkrescue -o doom-os.iso iso
