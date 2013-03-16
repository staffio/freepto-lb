#!/bin/bash
set -x

# Check if user is root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ $# != 1 ];then
   echo "Wrong argument number"
   exit 1
fi
device=$1

# Check for bad block on the device:
badblocks -c 10240 -s -w -t random -v "${device}"

# Random data on the device:
dd if=/dev/urandom of="${device}"

# DD THE binary.img to a usb
dd if=binary.img of="${device}"

# Make the partition
img_bytes=$(stat -c %s binary.img)
img_bytes=$((img_bytes+1))

parted "${device}" -- mkpart primary "${img_bytes}B" -1

# Ecnrypt partition
cryptsetup --verbose --batch-mode luksFormat "${device}2" <<<freepto

# Open partition
cryptsetup luksOpen "${device}2" my_usb <<<freepto

# Make FS with label: "persistence"
mkfs.btrfs -L persistence /dev/mapper/my_usb

# Make a mount point
mkdir -p /mnt/my_usb

# Munt the partition
mount /dev/mapper/my_usb /mnt/my_usb/ -o noatime,nodiratime,compress=lzo

# Make the persistence.conf file
echo "/ union" > ~/persistence.conf
mv ~/persistence.conf /persistence.conf
mv /persistence.conf /mnt/my_usb

# Umount
umount /dev/mapper/my_usb

# Close LUKS
cryptsetup luksClose /dev/mapper/my_usb

