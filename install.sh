#!/bin/bash -x

HOSTNAME=$HOSTNAME

# umount
umount /dev/md*

# Stop raid devices
mdadm --stop /dev/md*
# Zero 'em all
mdadm --zero-superblock /dev/sd*

# Partition setup
# Delte them all
# TODO There may be more than 5 partitions
for partition in {1..6}; do
    sgdisk -d $partition /dev/sda 
done

# Setup partion table
sgdisk -n 2:$(sgdisk -f /dev/sda):+100M /dev/sda # /boot
for partnum in {3..5}; do
    sgdisk -n $partnum:$(sgdisk -f /dev/sda):+30G /dev/sda # /boot /var /home
done

sgdisk -N 6 /dev/sda # /mnt/data
sgdisk -n 1:34:2047 /dev/sda # BIOS boot partition

# Change patition types
for partnum in {2..6}; do
    sgdisk -t $partnum:fd00 /dev/sda #FD00: Raid
done
sgdisk -t 1:ef02 /dev/sda #EF02: BIOS boot partition

# Copy them for one disk to another
sgdisk --backup=table /dev/sda
sgdisk --load-backup=table /dev/sdb

# RAID 1 setup
# TODO remove warning -> -f -q ?
#mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]1 # BIOS boot 
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd[ab]2 # boot
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/sd[ab]3 # root
mdadm --create /dev/md2 --level=1 --raid-devices=2 /dev/sd[ab]4 # var
mdadm --create /dev/md3 --level=1 --raid-devices=2 /dev/sd[ab]5 # home
mdadm --create /dev/md4 --level=1 --raid-devices=2 /dev/sd[ab]6 # data 

mdadm --detail --scan >> /etc/mdadm.conf

# watch -n .1 cat /proc/mdstat

# Format partitions
mkfs.ext2 /dev/md0
for partnum in {1..4}; do
    mkfs.ext4 /dev/md${partnum}
done

# Download bootstrap image
mount /dev/md4 /mnt
wget -P /mnt http://archlinux.limun.org/iso/2013.11.01/archlinux-bootstrap-2013.11.01-x86_64.tar.gz 
tar xzvf /mnt/archlinux-bootstrap-2013.11.01-x86_64.tar.gz -C /mnt

# Entropy for pacman-key
apt-get install haveged
haveged -w 1024

# Setup mirrorlist
# TODO sed -i '///' /mnt/root.x86_64/etc/pacman.d/mirrorlist
vim /mnt/root.x86_64/etc/pacman.d/mirrorlist

# chroot
/mnt/root.x86_64/bin/arch-chroot /mnt/root.x86_64

# Setup pacman-key
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

# Mount partitions
mount /dev/md1 /mnt
mkdir /mnt/{boot,home,var}
mount /dev/md0 /mnt/boot
mount /dev/md2 /mnt/var
mount /dev/md3 /mnt/home

# Debian workaround
mkdir /run/shm

# Install base
pacstrap /mnt base

# Generate fstab
genfstab -p /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt

# Hostname
# echo "$HOSTNAME" > /etc/hostname
hostnamectl set-hostname $HOSTNAME

# Timezone
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

# locale setup
# TODO Add global variables and loop over them
sed -i '/^#fr_FR\|^#de_DE\|^#en_US/s/^#//' /etc/locale.gen
locale-gen
echo "LANG=en_US.utf8" > /etc/locale.conf

# Keyboard
# echo "KEYMAP=de-latin1" > /etc/vconsole.conf

# RAID config
pacman -S mdadm
mdadm --detail --scan >> /etc/mdadm.conf

# Kernel
# Add mdadm_udev hook
sed -i '/^HOOK/s/\(filesystems\)/mdadm_udev \1/' mkinitcpio.conf
mkinitcpio -p linux

# GRUB2
pacman -S grub
# Reduce timeout to 1 second
sed -i '/^GRUB_TIMEOUT/s/\(GRUB_TIMEOUT=\)\d/\11/' /etc/grub.d/grub

# Set root (/boot partition)
echo -e 'insmod mdraid\nset root=(md0)' >> /etc/grub.d/40_custom

# Install grub and generate config
grub-install --target=i386-pc --recheck --debug /dev/sda && grub-install --target=i386-pc --recheck --debug /dev/sdb 
grub-mkconfig -o /boot/grub/grub.cfg

# Network
# Prevent unpredictable network device naming 
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
#systemctl start dhcpcd@eth0.service
systemctl enable dhcpcd@eth0.service

# Early loading
# echo 'r8169' > /etc/modules-load.d/realtek.conf

# SSH
pacman -S openssh
systemctl enable sshd

# Exit chroot and umount
exit
exit
#reboot
# umount /tmp/root.x86_64/{tmp,run,sys,dev,proc,etc/resolv.conf}

# DEBUG: start over
# mount /dev/md1 /mnt; mount /dev/md0 /mnt/boot/; mount /dev/md2 /mnt/var/; mount /dev/md3 /mnt/home
# mount --rbind /proc /mnt/proc; mount --rbind /sys /mnt/sys; mount --rbind /dev /mnt/dev; mount --rbind /run /mnt/run
# cp /etc/resolv.conf /mnt/etc/resolv.conf
# chroot /mnt

