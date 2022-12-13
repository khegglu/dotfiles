#! /bin/bash

# My base install script of Arch Linux

# Filesystem mount warning
echo "This script will create and format the partitions as follows:"
echo "/dev/sda1 - 512Mib will be mounted as /boot/efi"
echo "/dev/sda2 - 40GiB will be used as /"
echo "/dev/sda3 - rest of space will be mounted as /home"
read -p 'Continue? [y/N]: ' fsok
if ! [ $fsok = 'y' ] && ! [ $fsok = 'Y' ]
then 
    echo "Edit the script to continue..."
    exit
fi

# Clear disk before partitioning
wipefs -a /dev/sda

# to create the partitions programatically (rather than manually)
# https://superuser.com/a/984637
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
  g # create gpt partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +512M # 512 MB boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +40G # 40 GB root parttion
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

# Format the partitions
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda2
mkfs.fat -F32 /dev/sda1

# Mount the partitions
mount /dev/sda2 /mnt
mount /dev/sda3 /mnt/home
mkdir -pv /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# Set up time
timedatectl set-ntp true

# Initate pacman keyring
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

# Installing core packages
pacstrap /mnt base base-devel linux linux-firmware intel-ucode efibootmgr dosfstools freetype2 iw wpa_supplicant dialog xorg xorg-server xorg-xinit mesa xf86-video-intel

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy post-install system configuration scripts to new /root
cp -rfv base-config.sh /mnt/root
cp -rfv workspace-install.sh /mnt/root
chmod a+x /mnt/root/base-config.sh
chmod a+x /mnt/root/workspace-install.sh

echo "After chrooting into newly installed OS, please run the base-config.sh by executing ./root/base-config.sh"
echo "After chrooting into newly installed OS, please run the workspace-install.sh by executing ./root/workspace-install.sh"
echo "Entering chroot..."
arch-chroot /mnt /bin/bash

