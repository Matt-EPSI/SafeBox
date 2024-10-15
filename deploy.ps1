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
$imagePath = "$env:USERPROFILE\image.img"
$tempFilePath = "$env:USERPROFILE\image.img.xz"
$mountPath = "X:"
$customScriptPath = "C:\chemin\vers\mon_script.sh"

# Télécharger l'image
try {
    Invoke-WebRequest -Uri $imageUrl -OutFile $tempFilePath -ErrorAction Stop
} catch {
    Write-Host "Erreur lors du téléchargement de l'image : $_"
    exit 1
}

# Décompresser l'image (nécessite 7-Zip)
try {
    & "C:\Program Files\7-Zip\7z.exe" e $tempFilePath -o"$env:USERPROFILE\" -y -ErrorAction Stop
} catch {
    Write-Host "Erreur lors de la décompression de l'image : $_"
    exit 1
}

# Monter l'image (nécessite ImDisk)
try {
    imdisk -a -f $imagePath -m $mountPath -o remount -ErrorAction Stop
} catch {
    Write-Host "Erreur lors du montage de l'image : $_"
    exit 1
}

# Modifier les fichiers de configuration
Set-Content -Path "$mountPath\config.txt" -Value "dtoverlay=w1-gpio`nhdmi_force_hotplug=1"
Add-Content -Path "$mountPath\cmdline.txt" -Value " console=serial0,115200"

# Ajouter des fichiers personnalisés
if (Test-Path $customScriptPath) {
    Copy-Item $customScriptPath -Destination "$mountPath\home\pi\" -ErrorAction Stop
} else {
    Write-Host "Le fichier de script personnalisé n'existe pas : $customScriptPath"
}

# Démonter l'image
imdisk -D -m $mountPath

# Supprimer le fichier temporaire
Remove-Item $tempFilePath -ErrorAction SilentlyContinue

Write-Host "L'image Raspberry Pi OS a été personnalisée avec succès."
