
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

if [[ $HOSTNAME != "gnu" ]]; then
    echo "Executing in testing mode..."
    exit
fi

echo 
read -p "The disk $DISK will be complete deleted. Continue? (yes/no): " CONTINUE
if [[ $CONTINUE != "yes" ]]; then
    echo "Aborting installation."
    exit
fi

echo 
read -p "REALLY? (YES/NO): " CONTINUE
if [[ $CONTINUE != "YES" ]]; then
    echo "Aborting installation."
    exit
fi

echo
echo "Installing GNU-Guix in $DISK"
echo "Host: $HOST"
echo

# make a new GPT partition table
sudo parted $DISK mklabel gpt

# make EFI & btrfs partitions
sudo parted $DISK mkpart GUIX-EFI fat32 1M 100M
sudo parted $DISK mkpart guix btrfs 100M 100%

# set esp flag in EFI partition
sudo parted $DISK set 1 esp on

# make the filesystems
sudo mkfs.vfat -F32 -n GUIX-EFI /dev/disk/by-partlabel/GUIX-EFI
sudo mkfs.btrfs -L guix /dev/disk/by-partlabel/guix -f

# mount the disk & create the subvolumes
sudo mount LABEL=guix /mnt
sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@gnu
sudo btrfs subvolume create /mnt/@home
sudo umount -R /mnt

# make the directories
sudo mount LABEL=guix /mnt -osubvol=/@
sudo mkdir -p /mnt/home
sudo mkdir -p /mnt/gnu
sudo mkdir -p /mnt/boot/efi

# mount all in the right place
sudo mount LABEL=guix /mnt/home -osubvol=/@home
sudo mount LABEL=guix /mnt/gnu -osubvol=/@gnu
sudo mount LABEL=GUIX-EFI /mnt/boot/efi

### installation
herd start cow-store /mnt
sudo guix archive --authorize < signing-key.pub
guix time-machine -C ./channels.scm -- system init ../system-config.scm /mnt --substitute-urls='https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org'
