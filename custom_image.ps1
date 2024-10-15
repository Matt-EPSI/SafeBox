vagrant init
vagrant up --provider=virtualbox
vagrant ssh

wget --progress=bar:noscroll https://downloads.raspberrypi.com/raspios_full_armhf/images/raspios_full_armhf-2024-07-04/2024-07-04-raspios-bookworm-armhf-full.img.xz
unxz -v 2024-07-04-raspios-bookworm-armhf-full.img.xz
sudo apt-get install -y qemu-utils

qemu-img info 2024-07-04-raspios-bookworm-armhf-full.img 
qemu-img resize 2024-07-04-raspios-bookworm-armhf-full.img +6G
fdisk -l 2024-07-04-raspios-bookworm-armhf-full.img

growpart 2024-07-04-raspios-bookworm-armhf-full.img 2
fdisk -l 2024-07-04-raspios-bookworm-armhf-full.img

DEVICE=$(sudo losetup -f --show -P 2024-07-04-raspios-bookworm-armhf-full.img)
echo $DEVICE
lsblk -o name,label,size $DEVICE

losetup -l

DEVICE=$DEVICE
sudo e2fsck -f ${DEVICE}p2
sudo resize2fs ${DEVICE}p2
mkdir -p rootfs
sudo mount ${DEVICE}p2 rootfs/
ls rootfs/

cat rootfs/etc/fstab
ls rootfs/boot/

sudo mount ${DEVICE}p1 rootfs/boot/
