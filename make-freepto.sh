#!/bin/bash
read -p "Definisci il devices: " devicel
read -p "Dimensione persistenza: " bytes

# Check for bad block on the device:
badblocks -c 10240 -s -w -t random -v "${devicel}"

# Random data on the device:
dd if=/dev/urandom of="${devicel}"

# DD THE binary.img to a usb
dd if=binary.img of="${devicel}"

# Make the partition
read bytes _ < <(du -bcm binary.img |tail -1); echo $bytes

parted "${devicel}" mkpart primary "${bytes}" "${usb_size}"

# Ecnrypt partition
cryptsetup --verbose --verify-passphrase luksFormat "${devicel}2"

# Open partition
cryptsetup luksOpen "${devicel}2" my_usb

# Make FS with label: "persistence"
mkfs.ext3 -L persistence /dev/mapper/my_usb

# Make a mount point
mkdir -p /mnt/my_usb

# Munt the partition
mount /dev/mapper/my_usb /mnt/my_usb/

# Make the persistence.conf file
echo "/ union" > ~/persistence.conf && mv ~/persistence.conf \
                      /persistence.conf && mv /persistence.conf /mnt/my_usb

# Umount
umount /dev/mapper/my_usb

# Close LUKS
cryptsetup luksClose /dev/mapper/my_usb
