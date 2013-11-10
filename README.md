# hetzner-arch


## Description

ArchLinux install script for a Hetzner root server

## Customization

You definetely should edit this script before running it.
By default it will create a RAID 1 array with following partition scheme:

```
# 
# /etc/fstab: static file system information
#
# <file system>         <dir>           <type>          <options>                      <dump> <pass>
/dev/md1                /               ext4            rw,relatime,data=ordered        0     1

/dev/md0                /boot           ext2            rw,relatime                     0     2

/dev/md2                /var            ext4            rw,relatime,data=ordered        0     2

/dev/md3                /home           ext4            rw,relatime,data=ordered        0     2

/dev/md4                /mnt/data       ext4            rw,relatime,data=ordered        0     2

```

## Installation

```
wget https://raw.github.com/pschmitt/hetzner-arch/master/install.sh
sh install.sh
```

## Usage

By default this script will install arch on /dev/sd[ab]

### Options

-r: Rescue mode
    Try to mount HDDs and chroot to it


