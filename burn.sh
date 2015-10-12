#!/bin/sh
# burn.sh

dd bs=512 count=2880 if=/dev/zero of=temp/boot.img
mkfs.vfat -F12 -s1 -n OSBOOT temp/boot.img
MOUNT_RESULT=`hdiutil mount temp/boot.img`
MOUNT_DEVICE=`echo $MOUNT_RESULT | awk '{print $1}'`
MOUNT_PATH=`echo $MOUNT_RESULT | awk '{print $2}'`
cp -v temp/KLOADER.IMG $MOUNT_PATH
sleep 3
umount $MOUNT_DEVICE
dd bs=512 count=1 if=temp/bootsector.img of=temp/boot.img conv=notrunc
mv temp/boot.img bin
