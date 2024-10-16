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
