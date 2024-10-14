# Vérifier si Chocolatey est installé, sinon l'installer
if (!(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Installer 7-Zip et ImDisk avec Chocolatey
choco install 7zip.install -y
choco install imdisk-toolkit -y

# Recharger le PATH pour avoir accès aux nouvelles commandes
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")


# Définir les variables
$imageUrl = "https://downloads.raspberrypi.com/raspios_full_armhf/images/raspios_full_armhf-2024-07-04/2024-07-04-raspios-bookworm-armhf-full.img.xz"
$imagePath = "C:\%USERNAME%\image.img"
$mountPath = "X:"

# Télécharger l'image
Invoke-WebRequest -Uri $imageUrl -OutFile "$imagePath.xz"

# Décompresser l'image (nécessite 7-Zip)
& "C:\Program Files\7-Zip\7z.exe" e "$imagePath.xz" -o"C:\chemin\vers\"

# Monter l'image (nécessite ImDisk)
imdisk -a -f $imagePath -m $mountPath

# Modifier les fichiers de configuration
Set-Content -Path "$mountPath\config.txt" -Value "dtoverlay=w1-gpio`nhdmi_force_hotplug=1"
Add-Content -Path "$mountPath\cmdline.txt" -Value " console=serial0,115200"

# Ajouter des fichiers personnalisés
Copy-Item "C:\chemin\vers\mon_script.sh" -Destination "$mountPath\home\pi\"

# Démonter l'image
imdisk -D -m $mountPath

Write-Host "L'image Raspberry Pi OS a été personnalisée avec succès."