#!/bin/bash

green="\e[0;32m\033[1m"
red="\e[0;31m\033[1m"
blue="\e[0;34m\033[1m"
cyan="\e[0;36m\033[1m"
yellow="\e[0;33m\033[1m"
end="\033[0m\e[0m"

function C_PARTITION(){
    clear
    echo -e "${cyan}[+] Config Disk\n"
    echo -e "${yellow}  [-] It will create /boot, /, /home and swap partitions.\n      Swap partitions itself with the GiB you leave free. ${cyan}\n"
    echo -e "---- Disks Detected ----"
    lsblk | grep "disk"

    echo
    read -p "   - Disk Name: " disk
    read -p "   - Partition Boot Size (MiB): " boot
    read -p "   - Partition Root Size (GiB): " root
    read -p "   - Partition Home Size (GiB): " home
 
    parted /dev/$disk mklabel msdos                         &> /dev/null
    parted /dev/$disk mkpart primary fat32 1MiB $boot       &> /dev/null
    parted /dev/$disk set 1 boot on                         &> /dev/null
    parted /dev/$disk mkpart primary ext4 $boot $root       &> /dev/null
    parted /dev/$disk mkpart primary ext4 $root $home       &> /dev/null
    parted /dev/$disk mkpart primary linux-swap $home 100%  &> /dev/null

    mkfs.vfat -F 32 /dev/$disk"1"  &> /dev/null
    mkfs.ext4 /dev/$disk"2"        &> /dev/null
    mkfs.ext4 /dev/$disk"3"        &> /dev/null
    mkswap /dev/$disk"4"           &> /dev/null
    swapon /dev/$disk"4"

    echo -e "${green}\nSuccessfully Created${end}"
    sleep 3

}

function I_ARCHLINUX(){
    clear
    echo -e "${cyan}[+] Install ArchLinux\n"

    # ---------- Mount Partitions ----------
    echo -e "  [-] Mount Partitions${end}"
    mount /dev/$disk"2" /mnt
    mkdir /mnt/boot
    mkdir /mnt/home
    mount /dev/$disk"1" /mnt/boot
    mount /dev/$disk"3" /mnt/home
    sleep 2
    
    # ---------- Install Basic System ---------- 
    pacstrap /mnt linux linux-firmware networkmanager grub wpa_supplicant base base-devel sudo neovim neofetch git
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # ---------- Configuration System ----------
    C_SCRIPT_CONFIG
    chmod +x /mnt/conf_arch.sh
    arch-chroot /mnt /conf_arch.sh
    rm -f /mnt/conf_arch.sh install-archlinux.sh

    # ---------- Reboot System ----------
    echo -e "${green}Successful Installation\n"
    echo -e "${red}[!] System Reboot..."
    sleep 5
    shutdown -r now
}

function C_SCRIPT_CONFIG(){

cat > /mnt/conf_arch.sh << EOF
#!/bin/bash

# ---------- Create User ----------
clear
echo -e "${cyan}\n[+] Create User\n"
read -p "User Name: " user
read -p "User pass: " pass
pass=\$(openssl passwd -crypt \$pass)
useradd -m \$user -p \$pass -G wheel -s /bin/bash
echo -e "\nUser: \$user created"
sleep 2

# ---------- Configure Zone, keyboard, Localization and Language ----------
echo -e "Configure zone, keyboard , localization and language\n"
sleep 2
timedatectl set-timezone America/Mexico_City
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers
sed -i "s/#es_MX.UTF/es_MX.UTF/" /etc/locale.gen
sed -i "s/#en_US.UTF/en_US.UTF/" /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf
    
# ---------- Configure Grub ----------
grub-install /dev/$disk
grub-mkconfig -o /boot/grub/grub.cfg

# ---------- Configure Host ----------
read -p "Host Name: " hname
echo \$hname > /etc/hostname

cat >> /etc/hosts << EOFI

127.0.0.1       localhost
::1             localhost
127.0.0.1       \$hname.localhost \$hname

EOFI

# ---------- Enabling Services ----------
systemctl enable NetworkManager  &> /dev/null
systemctl enable wpa_supplicant  &> /dev/null

# ---------- Install blackarch ----------
echo -e "\nInstall Blackarch\n"
sleep 2
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
./strap.sh
rm -f strap.sh

EOF

}

function options(){
    opc=0

    while [[ $opc -ne 5 ]]; do
        clear
	    echo -e "${blue}"
	    echo -e "1 - Install Basic ArchLinux\n"
	    sleep 0.20
	    echo -e "2 - Install XFCE\n"
    	sleep 0.20
	    echo -e "3 - Install awesomeWM\n"
	    sleep 0.20
	    echo -e "4 - Install All\n"
	    sleep 0.20
	    echo -e "5 - Exit\n\n"
	    sleep 0.20
	    read -p "Option: " opc
	    echo -e "${end}"

        case $opc in
            1)  C_PARTITION
                I_ARCHLINUX;;
            2)  ;;
            3)  ;;
            4)  ;;
            5)  echo -e "${red}[x] Exiting..."
                sleep 3;;
            *)  echo -e "${red}[x] Invalid Option [1 - 6]\n${end}"
                sleep 3;;
        esac
    done
}

options
