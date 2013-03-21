freepto-lb
==========

crypto-usb for activist

Chroot Debian Sid
=================

1. Make chroot:

 $ sudo debootstrap --include=debian-keyring,debian-archive-keyring,cryptsetup,live-build,git,ca-certificates --arch i386 sid ~/freepto-lb/

2. User chroot:

 $ sudo chroot ~/freepto-lb /bin/bash

3. Cache for APT (optional):

 $ apt-get install apt-cacher-ng
 $ /etc/init.d/apt-cacher-ng start
 $ export http_proxy=http://localhost:3142/

Build
=====

 $ lb config && lb build

Make Freepto
============

1. use "dmesg" to identify the usb device

 $ dmesg

2. run make-freepto.sh

 $ bash make-freepto.sh /dev/sdd
