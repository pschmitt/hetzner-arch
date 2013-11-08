#!/bin/sh

# Stop raid devices
mdadm --stop /dev/md*
# Zero them
mdadm --zero-superblock /dev/sd*

# Partition setup
# Delte them all
for partition in {1..5}; do
    sgdisk -d $partition /dev/sda 
done

# Setup partion table
sgdisk -n 1:$(sgdisk -f /dev/sda):+100M /dev/sda # /boot
for partnum in {2..4}; do
    sgdisk -n $partnum:$(sgdisk -f /dev/sda):+30G /dev/sda # /boot /var /home
done

sgdisk -N 5 /dev/sda # /mnt/data

# Change patition types
for partnum in {1..5}; do
    sgdisk -t $partnum:fd00 /dev/sda #FD00: Raid
done

# Copy them for one disk to another

# RAID 1 setup
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]3 # root
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sd[ab]1 # boot
mdadm --create /dev/md2 --level=1 --raid-devices=2 /dev/sd[ab]2 # var
mdadm --create /dev/md3 --level=1 --raid-devices=2 /dev/sd[ab]4 # home
mdadm --create /dev/md4 --level=1 --raid-devices=2 /dev/sd[ab]5 # data 


# Download bootstrap image
wget -P /tmp http://archlinux.limun.org/iso/2013.11.01/archlinux-bootstrap-2013.11.01-x86_64.tar.gz /tmp
tar xzvf /tmp/archlinux-bootstrap-2013.11.01-x86_64.tar.gz -C /tmp


