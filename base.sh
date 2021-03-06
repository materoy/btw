#!/bin/bash

timedatectl set-ntp true

echo List of all disks
lsblk

echo Enter BOOT disk
read boot_disk

echo Enter ROOT disk 
read root_disk

echo Enter HOME disk
read home_disk

echo Enter swap partition
read swap_disk

echo Erasing root disk ...
mkfs.ext4 $root_disk

# Mount disks
mount $root_disk /mnt

if [[ $boot_disk ]]; then    

  read -p "Wipe boot partition?  " -n 1 -r
  REPLY = "n"
  echo 
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    mkfs.fat -F 32 $boot_disk
  fi

  mount $boot_disk /mnt/boot
fi

if [[ $home_disk ]]; then
  mkfs.ext4 $home_disk
  mount $home_disk /mnt/home
fi

if [[ $swap_disk ]]; then
  mkswap $swap_disk
  swapon $swap_disk
  
fi

# Base install
pacstrap /mnt base linux linux-firmware


genfstab -U /mnt >> /mnt/etc/fstab

arch-choot /mnt

ln -sf /usr/share/zoneinfo/Africa/Nairobi /etc/localtime
hwclock --systohc
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=us" >> /etc/vconsole.conf

# Hostname
echo Enter hostname
read hostname

echo $hostname >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

mkinitcpio -P

echo Input root password
read -s root_passwd

printf "$root_passwd\n$root_passwd" | passwd

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

pacman -S --noconfirm grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools reflector base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call tlp virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

read -p "Install Nvidia shit ? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
fi


grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager.service
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable tlp # You can comment this command out if you didn't install tlp, see above
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid


# User related
read -p "Add non root user ? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo Enter username
    read username

    echo Enter password for $username
    read -s user_passwd

    useradd -m $username

    printf "$user_passwd\n$user_passwd" | passwd $username

    usermod -aG libvirt $username

    echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username

fi

printf "\e[1;32mDone! Type exit, umount -a and reboot.\e[0m"


exit
umount -R /mnt


read -p "Would you gladly want to reboot ? " -n 1 -r
echo  
if [[ $REPLY =~ ^[Yy]$ ]]
then
  reboot
fi
