
echo
lsblk -o +LABEL
echo 
read -p "In which disk will GNU-Guix be instaled: " DISK
DISK="/dev/$DISK"
if [[ ! -b $DISK ]]; then
    echo "The disk $DISK doesn't exist."
    exit
fi

echo 
read -p "Wich host install (jtx or ffm): " HOST
if [[ $HOST != "jtx" ]] && [[ $HOST != "ffm" ]]; then
    echo "The host $HOST doesn't exists"
    exit
fi
HOST=$HOST-guix

echo 
read -p "The disk $DISK will be complete deleted. Continue? (yes/no): " CONTINUE
if [[ $CONTINUE != "yes" ]]; then
    echo "Aborting installation."
    exit
fi

echo
echo "Installing GNU-Guix in $DISK"
echo "Host: $HOST"
echo

# make a new GPT partition table
parted $DISK mklabel gpt

# make EFI & btrfs partitions
parted $DISK mkpart GUIX-EFI fat32 1M 100M
parted $DISK mkpart guix btrfs 100M 100%

# set esp flag in EFI partition
parted $DISK set 1 esp on

# make the filesystems
mkfs.vfat -F32 -n GUIX-EFI /dev/disk/by-partlabel/GUIX-EFI
mkfs.btrfs -L guix /dev/disk/by-partlabel/guix -f

# mount the disk & create the subvolumes
mount LABEL=guix /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@gnu
btrfs subvolume create /mnt/@home
umount -R /mnt

# make the directories
mount LABEL=guix /mnt -osubvol=/@
mkdir -p /mnt/home
mkdir -p /mnt/gnu
mkdir -p /mnt/boot/efi

# mount all in the right place
mount LABEL=guix /mnt/home -osubvol=/@home
mount LABEL=guix /mnt/gnu -osubvol=/@gnu
mount LABEL=GUIX-EFI /mnt/boot/efi

### get the config files
wget https://raw.githubusercontent.com/jotix/guix-config/refs/heads/main/system-config.scm
wget https://raw.githubusercontent.com/jotix/guix-config/refs/heads/main/install/channels.scm
wget https://raw.githubusercontent.com/jotix/guix-config/refs/heads/main/install/signing-key.pub

### installation
herd start cow-store /mnt
guix archive --authorize < signing-key.pub
guix time-machine -C ./channels.scm -- system init ./system-config.scm /mnt --substitute-urls='https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org'
