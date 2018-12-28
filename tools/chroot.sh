#!/bin/bash

###########################################
#Generic chroot functions
###########################################


# chroot.sh NEWROOT [COMMAND] [USER[:GROUP]]

function chrootMountAll { #mount and cp all staf to chroot
  cp /usr/bin/qemu-arm-static $1"/usr/bin/"
  for i in /dev /dev/pts /proc /sys /run; do mount --bind $i $1$i; done 
  mount -o bind /etc/resolv.conf $1/"etc/resolv.conf"	
}

function chrootUmountAll { #umount all staf from chroot
  umount $1/"etc/resolv.conf"
  for i in /dev/pts /dev /proc /sys /run; do umount $1$i; done

}
	
[ -z $1 -o  $UID -ne 0 ] && echo "error chroot" && exit 1
chrootMountAll $1
if [ ! -z $3 ]; then
  echo "debug info $3"
  chroot --userspec=$3 $1 $2 
else
  chroot $1 $2
fi
chrootUmountAll $1

