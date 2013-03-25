#!/bin/bash
#set -x

# Check if user is root
if [ "$(id -u)" != "0" ]; then
   echo "[-] This script must be run as root" 1>&2
   exit 1
fi

if [ $# != 1 ];then
   echo "[-] Wrong argument number"
   exit 1
fi
device=$1

# check dependencies
if ! which mkfs.btrfs &> /dev/null; then
     echo "[-] No btrfs. Setting up btrfs-tools"
     sudo apt-get --force-yes --yes install btrfs-tools && echo "[+] Btrfs-tools installed!"
fi
if ! which cryptsetup &> /dev/null; then
     echo "[-] No cryptsetup. Setting up cryptsetup"
     sudo apt-get --force-yes --yes install cryptsetup && echo "[+] Cryptsetup installed!"
fi

# Check for bad block on the device:
badblocks -c 10240 -s -w -t random -v "${device}"
echo "[+] Badblock check completed!"

# Random data on the device:
echo "[+] Writing random data on the device!"
dd if=/dev/urandom of="${device}"
echo "[+] Completed!"

# DD THE binary.img to a usb
echo "[+] Starting DD"
dd if=binary.img of="${device}"
echo "[+] Completed!"

# Make the partition
echo "[+] Make ecnrypted and persistent partition"
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
