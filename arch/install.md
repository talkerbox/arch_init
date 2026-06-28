# Instalation process

Description of installation process

## Preparation
1. Download Arch image https://archlinux.org/download/
2. (skip this step if installation on Virtual Machine (VM)) Prepare bootable USB flash drive with image https://wiki.archlinux.org/title/USB_flash_installation_medium
3. If installation on VM - create VM and mount ISO image with Arch. If real machine - reboot and select bootable USB drive for boot.

## Pre-install configurations
After booting in Live Arch, run follow script (or just uncommented parts manually)

```bash
### Set keyboard layout to US (you can change to any other, but US is by default)
# localectl list-keymaps
loadkeys us

### Set fancy console font
setfont Lat2-Terminus16

### Check if loaded under UEFIx64
if [ $(cat /sys/firmware/efi/fw_platform_size) -eq 64 ];then echo "Yes, UEFI is x64";else echo "No, UEFI is not 64, or not UEFI!";fi

### Check network connection
ip link
ping -c 3 ping.archlinux.org

### Set time and data
# timedatectl list-timezones
timedatectl set-timezone Europe/Vinlius
```

## Filesystem preparation
Partitioning. Create 4 basic partition: `efi`, `swap`, `/` and `/home`. Use `fdisk`. Here is a helper, adjust partition size if needed:
```bash
### prepare partition table
fdisk -l
fdisk /dev/<the_disk_to_be_partitioned>

### New GPT partition label
g

### efi
n
1

+1G
t
uefi

### swap
n
2

+4G
t
2
swap

### / (root)
n
3

+30G
t
3
24

### /home
n
4

+50G
t
4
linux

### preview and save partition table to disk
p
w
```

Format partitions.
```bash
### efi
mkfs.fat -F 32 /dev/<efi_system_partition>

### swap
mkswap /dev/<swap_partition>

### / (root)
mkfs.ext4 /dev/<root_partition>

### /home
mkfs.ext4 /dev/<root_partition>
```

Mount the the filesystem to `/mnt`:
```bash
mount --mkdir /dev/<root_partition> /mnt
mount --mkdir /dev/<efi_partition> /mnt/boot
mount --mkdir /dev/<home_partition> /mnt/home
```

Enable `swap`:
```bash
swapon /dev/<swap_partition>
```


## Install
Select the mirrors. move closest mirrors based on location to the top of file `/etc/pacman.d/mirrorlist`.

Install essential package (minimal setup, all other packages will be installed in the post-installation configuration step):
```bash
pacstrap -K /mnt base linux linux-firmware vim wget
```

## Initial configuration
Create `fstab` based on current mounted filesystem:
```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

Chroot to the newly installed system for the furter configuration:
```bash
arch-chroot /mnt
```

Basic configuration of time, locales, hostname, password:
```bash
### Datetime
ln -sf /usr/share/zoneinfo/Europe/Vilnius /etc/localtime
hwclock --systohc

### Localization (if needed).
### Uncomment locales in /etc/locale.gen
# vim /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

### Create hostname
echo "tbxarch" > /etc/hostname

### Set root password
passwd
```

Setup Boot Loader (GRUB):
```bash
### Install grub and efibootmgr
pacman -S grub efibootmgr

### mount efi partition to any mountpoint (`/mnt/boot` for example)
fdisk -l
mount --mkdir /dev/<efi_partition> /mnt/boot

### install and configure GRUB to efi partition
grub-install --target=x86_64-efi --efi-directory=/mnt/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

### unmount efi partition
umount /mnt/boot
```

## Reboot and next steps
Exit from chroot and reboot:
```bash
exit
reboot
```

Installation is done! Now you can login to the installed system under the `root` user and continue further configuration by this [guide](./configuration.md).
