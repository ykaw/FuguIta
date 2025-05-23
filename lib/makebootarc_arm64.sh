#!/bin/sh

set -x

mkdir 'bootstuff.arm64' || exit 1
cd 'bootstuff.arm64' || exit 1

mkdir -p efi
mkdir -p efi/boot
mkdir -p efi/openbsd
mkdir -p overlays
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2710-rpi-2-b.dtb bcm2710-rpi-2-b.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b-plus.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2710-rpi-3-b.dtb bcm2710-rpi-3-b.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2710-rpi-cm3.dtb bcm2710-rpi-cm3.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2711-rpi-4-b.dtb bcm2711-rpi-4-b.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2711-rpi-400.dtb bcm2711-rpi-400.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bcm2711-rpi-cm4.dtb bcm2711-rpi-cm4.dtb
cp -p /usr/local/share/raspberrypi-firmware/boot/bootcode.bin bootcode.bin

# config.txt not found: replace this with a command line to create config.txt
echo 'arm_64bit=1\nenable_uart=1\ndtoverlay=disable-bt\nkernel=u-boot.bin' > config.txt

# bootaa64.efi not found: replace this with a command line to create efi/boot/bootaa64.efi
cp /usr/mdec/BOOTAA64.EFI efi/boot/bootaa64.efi

# startup.nsh not found: replace this with a command line to create efi/boot/startup.nsh
echo bootaa64.efi > efi/boot/startup.nsh

# bootaa64.efi not found: replace this with a command line to create efi/openbsd/bootaa64.efi
cp /usr/mdec/BOOTAA64.EFI efi/openbsd/bootaa64.efi

cp -p /usr/local/share/raspberrypi-firmware/boot/fixup.dat fixup.dat
cp -p /usr/local/share/raspberrypi-firmware/boot/fixup4.dat fixup4.dat
cp -p /usr/local/share/raspberrypi-firmware/boot/overlays/disable-bt.dtbo overlays/disable-bt.dtbo
cp -p /usr/local/share/raspberrypi-firmware/boot/start.elf start.elf
cp -p /usr/local/share/raspberrypi-firmware/boot/start4.elf start4.elf

# found u-boot.bin in multiple paths
# please select (uncomment) from following lines
# dup: cp -p /usr/local/share/u-boot/mvebu_espressobin-88f3720/u-boot.bin u-boot.bin
# dup: cp -p /usr/local/share/u-boot/mvebu_mcbin-88f8040/u-boot.bin u-boot.bin
# dup: cp -p /usr/local/share/u-boot/qemu_arm64/u-boot.bin u-boot.bin
cp -p /usr/local/share/u-boot/rpi_arm64/u-boot.bin u-boot.bin

tar cvzf '../bootstuff.arm64.tar.gz' .
cd ..
rm -r 'bootstuff.arm64'
