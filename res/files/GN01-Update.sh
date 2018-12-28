#!/bin/bash
#
#-----------------------------------------------------------------------
#
# Script for GN-01 Data Transfer and Update upon USB hard disk insertion
# It is called thru UDEV with :
#  - the device name (sda1, ...) given as the first parameter
#
#-----------------------------------------------------------------------

BackupPath="/mnt/backup"
XCSoarData="/home/rbe/XCSoarData/"
XCSoarBin="/home/rbe/"

# Log beggining of backup
/usr/bin/logger GN01-Update - Beginning at `date`

# if needed, create the mount directory
if [ ! -d /mnt/backup ] ; then mkdir $BackupPath ; fi

# if your backup disk is formatted in ext2 or ext3, use following line to mount the backup disk
#/bin/mount -t auto /dev/$1 /mnt/backup
# or if your backup disk is formatted in FAT32, use following line to mount the backup disk
/bin/mount -t vfat -o shortname=mixed,iocharset=utf8 /dev/$1 $BackupPath


# Check if directory for flight logs exists, if not than create it
if [ ! -d "$BackupPath/logs" ]; then
  mkdir $BackupPath/logs  
fi
/usr/bin/logger copying flight logs
/usr/bin/rsync -rtv $XCSoarData/logs/ $BackupPath/logs

# Check if directory for profiles exists, if not then create it
if [ ! -d "$BackupPath/profiles" ]; then
  mkdir $BackupPath/profiles
fi
/usr/bin/logger copying profile files
/usr/bin/rsync -rtv $XCSoarData/*.prf $BackupPath/profiles

# Delete files if stated in delete.txt
if [ -f "$BackupPath/To-GN01/delete.txt" ]; then
while read line
do
	if [ "$line" = "logs" ]
	then
		rm -f $XCSoarData/logs/*
	elif [ "$line" = "xcm" ]
	then
		rm -f $XCSoarData/*.xcm
	elif [ "$line" = "txt" ]
	then
		rm -f $XCSoarData/*.txt
	elif [ "$line" = "prf" ]
	then 
		rm -f $XCSoarData/*.prf
                cp $XCSoarBin/.default.prf $XCSoarData/default.prf
	elif [ "$line" = "cup" ]
	then 
		rm -f $XCSoarData/*.cup
	elif [ "$line" = "*" ]
	then
		rm -f $XCSoarData/*
                cp $XCSoarBin/.default.prf $XCSoarData/default.prf
                cp $XCSoarBin/.custom.xci $XCSoarData/custom.xci
	fi
done < $BackupPath/To-GN01/delete.txt
rm -f $BackupPath/To-GN01/delete.txt
fi

/usr/bin/logger copying data files to GN-01
/usr/bin/rsync -rtv $BackupPath/To-GN01/ $XCSoarData
chown -fR rbe $XCSoarData

if [ -f "$BackupPath/xcsoar_gn01" ]; then
  cp $BackupPath/xcsoar_gn01 $XCSoarBin/xcsoar_new
  sudo rm $BackupPath/xcsoar_gn01
  /bin/sync
  sudo rm $XCSoarBin/xcsoar_backup
  mv $XCSoarBin/xcsoar_gn01 $XCSoarBin/xcsoar_backup
  chmod +x $XCSoarBin/xcsoar_backup
  chown rbe $XCSoarBin/xcsoar_backup
  /bin/sync
  mv $XCSoarBin/xcsoar_new $XCSoarBin/xcsoar_gn01
  chmod +x $XCSoarBin/xcsoar_gn01
  chown rbe $XCSoarBin/xcsoar_gn01
  /bin/sync
  /bin/umount $BackupPath
  sudo reboot
fi

if [ -f "$BackupPath/GN01-rootfs.tgz" ]; then
  tar -xzf $BackupPath/GN01-rootfs.tgz -C /
  /bin/sync
  rm $BackupPath/GN01-rootfs.tgz
  /bin/sync
  /bin/umount $BackupPath
  sudo reboot 
fi

# force sync of files to disk before unmounting
/bin/sync

# unmount the backup disk
/bin/umount $BackupPath

# Log end of backup
/usr/bin/logger Backup - End at `date`
