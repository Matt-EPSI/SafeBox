# Chemin du répertoire de travail
$downloadPath = Join-Path $env:USERPROFILE "Téléchargements"
$newFolderName = "RaspberryPi_Vagrant"
$newFolderPath = Join-Path $downloadPath $newFolderName

# Création du répertoire de travail
if (-not (Test-Path $newFolderPath)) {
    New-Item -ItemType Directory -Path $newFolderPath
    Write-Host "Le répertoire $newFolderPath a été créé."
} else {
    Write-Host "Le répertoire $newFolderPath existe déjà."
}

# Déplacer la console dans le répertoire créé
Set-Location -Path $newFolderPath

# Vérifier et installer Chocolatey si nécessaire
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installation de Chocolatey en cours..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey a été installé."
}

# Installation de Vagrant et VirtualBox
Write-Host "Installation de Vagrant et VirtualBox en cours..."
choco install vagrant virtualbox -y

# Initialiser Vagrant
Write-Host "Initialisation de Vagrant..."
vagrant init

# Configuration du Vagrantfile avec une box Ubuntu Jammy64
Write-Host "Mise à jour du Vagrantfile..."
Clear-Content -Path "$newFolderPath\Vagrantfile"
$VagrantfileContent = @"
Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.provider "virtualbox" do |vb|
        vb.memory = "8192"
        vb.cpus = "8"
        vb.gui = true
    end
end
"@
Set-Content -Path "$newFolderPath\Vagrantfile" -Value $VagrantfileContent

# Démarrage de la machine Vagrant
Write-Host "Démarrage de la machine Vagrant..."
vagrant up

# Connexion via SSH
Write-Host "Connexion à la machine Vagrant..."
vagrant ssh << 'EOF'

# Étapes à l'intérieur de la machine Vagrant
# Téléchargement de l'image Raspberry Pi OS
wget --progress=bar:noscroll https://downloads.raspberrypi.com/raspios_full_armhf/images/raspios_full_armhf-2024-07-04/2024-07-04-raspios-bookworm-armhf-full.img.xz

# Décompression de l'image
unxz -v 2024-07-04-raspios-bookworm-armhf-full.img.xz

# Installation de qemu-utils
sudo apt-get install -y qemu-utils

# Redimensionnement de l'image avec qemu-img
qemu-img info 2024-07-04-raspios-bookworm-armhf-full.img
qemu-img resize 2024-07-04-raspios-bookworm-armhf-full.img +6G

# Gestion des partitions avec fdisk et growpart
fdisk -l 2024-07-04-raspios-bookworm-armhf-full.img
growpart 2024-07-04-raspios-bookworm-armhf-full.img 2
fdisk -l 2024-07-04-raspios-bookworm-armhf-full.img

# Montage de l'image avec losetup
DEVICE=$(sudo losetup -f --show -P 2024-07-04-raspios-bookworm-armhf-full.img)
echo $DEVICE
lsblk -o name,label,size $DEVICE

# Vérification des partitions
losetup -l

# Redimensionnement du système de fichiers
sudo e2fsck -f ${DEVICE}p2
sudo resize2fs ${DEVICE}p2

# Création d'un répertoire et montage des systèmes de fichiers
mkdir -p rootfs
sudo mount ${DEVICE}p2 rootfs/
sudo mount ${DEVICE}p1 rootfs/boot/

# Suppression des fichiers dans /rootfs/dev/*
sudo rm -rf rootfs/dev/*

# Montage des systèmes de fichiers proc, sys, et dev
sudo mount -t proc /proc rootfs/proc/
sudo mount --bind /sys rootfs/sys/
sudo mount --bind /dev rootfs/dev/

# Connexion au Raspberry en émulation et mise à jour du système
sudo chroot rootfs/ << 'CHROOTEOF'
apt-get update -y
apt-get upgrade -y
sudo apt-get install libreoffice -y
CHROOTEOF

# Déconnexion du chroot
exit
EOF

Write-Host "Processus terminé."
