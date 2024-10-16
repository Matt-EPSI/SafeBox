# Chemin du répertoire Téléchargements de l'utilisateur
$downloadPath = Join-Path $env:USERPROFILE "Téléchargements"

# Nom du nouveau répertoire à créer
$newFolderName = "RaspberryPi_Vagrant"

# Chemin complet du nouveau répertoire
$newFolderPath = Join-Path $downloadPath $newFolderName

# Vérifier si le répertoire existe déjà
if (-not (Test-Path $newFolderPath)) {
    # Créer le répertoire
    New-Item -Path $newFolderPath -ItemType Directory
    Write-Host "Le répertoire a été créé : $newFolderPath"
} else {
    Write-Host "Le répertoire existe déjà : $newFolderPath"
}
# Déplacer la console dans le répertoire créé
Set-Location -Path $newFolderPath
Write-Host "La console a été déplacée dans : $newFolderPath"

# Fonction pour installer Chocolatey s'il n'est pas déjà installé
function Install-Chocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey n'est pas installé. Installation en cours..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey a été installé."
    } else {
        Write-Host "Chocolatey est déjà installé."
    }
}

# Fonction pour installer Vagrant
function Install-Vagrant {
    if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) {
        Write-Host "Installation de Vagrant en cours..."
        choco install vagrant -y
        Write-Host "Vagrant a été installé avec succès."
    } else {
        Write-Host "Vagrant est déjà installé."
    }
}

# Fonction pour installer VirtualBox
function Install-VirtualBox {
    if (-not (Get-Command VBoxManage -ErrorAction SilentlyContinue)) {
        Write-Host "Installation de VirtualBox en cours..."
        choco install virtualbox -y
        Write-Host "VirtualBox a été installé avec succès."
    } else {
        Write-Host "VirtualBox est déjà installé."
    }
}
# Appel des fonctions pour installer Chocolatey puis Vagrant
Install-Chocolatey
Install-Vagrant
Install-VirtualBox

Write-Host "Initialisation de Vagrant dans le répertoire : $newFolderPath"

#Initialise vagrant
vagrant init

# Vérifier si le fichier Vagrantfile a été créé
if (Test-Path "$newFolderPath\Vagrantfile") {
    Write-Host "Le fichier Vagrantfile a été créé avec succès."
} else {
    Write-Host "Échec de la création du fichier Vagrantfile."
}

$vagrantFilePath = Join-Path $newFolderPath "Vagrantfile"
# Vérifier si le fichier Vagrantfile existe
if (Test-Path $vagrantFilePath) {
    # Effacer le contenu du Vagrantfile
    Clear-Content -Path $vagrantFilePath
    Write-Host "Le contenu du fichier Vagrantfile a été effacé."
    
    # Ajouter les nouvelles configurations dans le Vagrantfile
    $newConfig = @"
Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"
    config.vm.provider "virtualbox" do |vb|
        vb.memory = "8192"
        vb.cpus = "8"
        vb.gui = true
    end
end
"@

    # Écrire les nouvelles configurations dans le Vagrantfile
    Set-Content -Path $vagrantFilePath -Value $newConfig
    Write-Host "Le fichier Vagrantfile a été mis à jour avec les nouvelles configurations."
} else {
    Write-Host "Le fichier Vagrantfile n'existe pas. Assurez-vous que Vagrant a été initialisé."
}




# Lancer la machine Vagrant
Write-Host "Démarrage de la machine Vagrant..."
vagrant up --provider=virtualbox

# Vérifier si la machine est correctement démarrée
$vagrantStatus = vagrant status --machine-readable | Select-String "state,running"
if ($vagrantStatus) {
    Write-Host "La machine Vagrant est en cours d'exécution."

    # Connexion à la machine via SSH
    Write-Host "Connexion à la machine Vagrant via SSH..."
    vagrant ssh
} else {
    Write-Host "Échec du démarrage de la machine Vagrant."
}

#Téléchargement de l'image cible sur le site de Raspberry, et décompression totale
wget --progress=bar:noscroll https://downloads.raspberrypi.com/raspios_full_armhf/images/raspios_full_armhf-2024-07-04/2024-07-04-raspios-bookworm-armhf-full.img.xz
unxz -v 2024-07-04-raspios-bookworm-armhf-full.img.xz

#Installation des paquets qemu
sudo apt-get install -y qemu-utils
sudo apt-get install -y qemu-user-static

#Redimensionnement de l'image
qemu-img info 2024-07-04-raspios-bookworm-armhf-full.img 
qemu-img resize 2024-07-04-raspios-bookworm-armhf-full.img +6G
fdisk -l 2024-07-04-raspios-bookworm-armhf-full.img
growpart 2024-07-04-raspios-bookworm-armhf-full.img 2
fdisk -l 2024-07-04-raspios-bookworm-armhf-full.img

DEVICE=$(sudo losetup -f --show -P 2024-07-04-raspios-bookworm-armhf-full.img)
echo $DEVICE
lsblk -o name,label,size $DEVICE

losetup -l
#Montage des disques
DEVICE=$DEVICE
sudo e2fsck -f ${DEVICE}p2
sudo resize2fs ${DEVICE}p2
mkdir -p rootfs
sudo mount ${DEVICE}p2 rootfs/
ls rootfs/

cat rootfs/etc/fstab
ls rootfs/boot/

sudo mount ${DEVICE}p1 rootfs/boot/
rm -rf /rootfs/dev/*
sudo mount -t proc /proc rootfs/proc/
sudo mount --bind /sys rootfs/sys/
sudo mount --bind /dev rootfs/dev/

#Connexion au Raspberry en émulation et mise à jour
sudo chroot rootfs/
apt-get update -y
apt-get upgrade -y

#Mise à jour du nom de l'ordinateur
echo "SafeBox" > /etc/hostname

#Installation libreoffice
sudo apt-get install libreoffice

#Changement du fond d'écran 
apt-get install -y feh
mkdir -p /home/pi/wallpapers
wget -q "https://image.tmdb.org/t/p/original/gjHZbURgyqjBMHQICu3VZQf41gF.jpg" -O /home/pi/wallpapers/background.jpg
DISPLAY=:0 feh --bg-scale "/home/pi/wallpapers/background.jpg"

#Désactivation de Piwiz
sudo apt purge piwiz

#Ajout d'utilisateur enfant
useradd enfant -p 

#Modification des serveurs DNS
apt-get install -y systemd-resolved
# Ajout des serveurs DNS dans le fichier resolved.conf
cat >> /etc/systemd/resolved.conf << EOL
DNS=193.110.81.1#kids.dns0.eu
DNS=2a0f:fc80::1#kids.dns0.eu
DNS=185.253.5.1#kids.dns0.eu
DNS=2a0f:fc81::1#kids.dns0.eu
DNSOverTLS=yes
EOL

#Lancement automatique au démarrage
systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

#Sortie de chroot
exit

#Démontage des médias
sudo umount -l rootfs/dev/
sudo umount -l rootfs/sys/
sudo umount -l rootfs/proc/
sudo losetup-d $DEVICE

#Compression de l'image et sortie de vagrant
xz -v 2024-07-04-raspios-bookworm-arm64.img
mv *.xz /vagrant/
exit 
logout
vagrant destroy -y
Exit-PSHostProcess