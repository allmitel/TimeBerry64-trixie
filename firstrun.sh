#!/bin/bash
## v0.02 - 09 octobre 2024
## révision en juillet 2025

## PREMIER SCRIPT DE LANCEMENT RASPBERRY PI - VERSION BOOKWORM
## ADAPTÉ DU SCRIPT DE BASE POUR LA CRÉATION DE LA CARTE
## CONTIENT :
## - création du nom de compte de base du système
## - wifi de base et accès
## - accès ssh
## -
set +e
##########################################################################################
#######
## VARIABLES

DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
export DEBIAN_VER


##########################################################################################
########
## FONCTIONS
recupPART_sda() {
cp /etc/fstab /etc/fstab-temp

local varpartuuidsda1=$(ls -alh /dev/disk/by-partuuid | awk '/sda1/ {print $9}')
local varuuidsda2=$(ls -alh /dev/disk/by-uuid | awk '/sda2/ {print $9}')
local varuuidsda3=$(ls -alh /dev/disk/by-uuid | awk '/sda3/ {print $9}')
#
cat << EOF >> /etc/fstab-temp

#Système sur disque externe WD - sda1 : NON MONTÉ !!!
#PARTUUID=$varpartuuidsda1   /       ext4    defaults,noatime        0       1


#OPTION EXT4 - Disque WD My Passport
#/dev/sda2 Pour TimeCapsule
UUID=$varuuidsda2       /media/TimeCapsule      ext4    rw,nosuid,noauto 0 0
#/dev/sda3 Pour partage & Transmission
UUID=$varuuidsda3       /media/WD  ext4    rw,nosuid,noatime,noauto 0 0

## MINIMISER L'USURE DE LA CARTE SD
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
#utilisation de log2ram à la place : https://github.com/azlux/log2ram
#tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0

EOF
}

recupUUID_sda() {
cat << EOF >> /etc/fstab-temp

##
## Récupération automatique des différents UUID/PARTUUID des partitions de /dev/sda
## Pour référence :
##

EOF

local varlabelsda1=$(ls -alh /dev/disk/by-label | awk '/sda1/ {print $9}')
local varuuidsda1=$(ls -alh /dev/disk/by-uuid | awk '/sda1/ {print $9}')
local varpartuuidsda1=$(ls -alh /dev/disk/by-partuuid | awk '/sda1/ {print $9}')
echo "## Partition sda1 — "$varlabelsda1" ##" >> /etc/fstab-temp
echo "## UUID         "$varuuidsda1 >> /etc/fstab-temp
echo "## PARTUUID     "$varpartuuidsda1 >> /etc/fstab-temp
echo "" >> /etc/fstab-temp
local varlabelsda2=$(ls -alh /dev/disk/by-label | awk '/sda2/ {print $9}')
local varuuidsda2=$(ls -alh /dev/disk/by-uuid | awk '/sda2/ {print $9}')
local varpartuuidsda2=$(ls -alh /dev/disk/by-partuuid | awk '/sda2/ {print $9}')
echo "## Partition sda2 — "$varlabelsda2" ##" >> /etc/fstab-temp
echo "## UUID         "$varuuidsda2 >> /etc/fstab-temp
echo "## PARTUUID     "$varpartuuidsda2 >> /etc/fstab-temp
echo "" >> /etc/fstab-temp
local varlabelsda3=$(ls -alh /dev/disk/by-label | awk '/sda3/ {print $9}')
local varuuidsda3=$(ls -alh /dev/disk/by-uuid | awk '/sda3/ {print $9}')
local varpartuuidsda3=$(ls -alh /dev/disk/by-partuuid | awk '/sda3/ {print $9}')
echo "## Partition sda3 — "$varlabelsda3" ##" >> /etc/fstab-temp
echo "## UUID         "$varuuidsda3 >> /etc/fstab-temp
echo "## PARTUUID     "$varpartuuidsda3 >> /etc/fstab-temp
echo "" >> /etc/fstab-temp
mv /etc/fstab-temp /etc/fstab
chown root:root /etc/fstab && sudo chmod 644 /etc/fstab
}


##########################################################################################
##########
## SCRIPT EFFECTIF

echo "Hostname"
## MODIFICATION DU HOSTNAME
CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname TimeBerry64
else
   echo TimeBerry64 >/etc/hostname
   sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\tTimeBerry64/g" /etc/hosts
fi


echo "SSH"
## ACTIVATION DE L'ACCÈS SSH
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh
else
   systemctl enable ssh
fi


echo "Premier compte"
## MODIFICATION DU NOM DU PREMIER COMPTE + MDP
FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`
if [ -f /usr/lib/userconf-pi/userconf ]; then
   /usr/lib/userconf-pi/userconf 'pi' '$5$WVPmlWg/gS$2yP6/n6B6WYQizZaKAocFhaCDXwxw3V7KJb5bSHyRt9'
else
   echo "$FIRSTUSER:"'$5$WVPmlWg/gS$2yP6/n6B6WYQizZaKAocFhaCDXwxw3V7KJb5bSHyRt9' | chpasswd -e
   if [ "$FIRSTUSER" != "pi" ]; then
      usermod -l "pi" "$FIRSTUSER"
      usermod -m -d "/home/pi" "pi"
      groupmod -n "pi" "$FIRSTUSER"
      if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
         sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=pi/"
      fi
      if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
         sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/pi/"
      fi
      if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
         sed -i "s/^$FIRSTUSER /pi /" /etc/sudoers.d/010_pi-nopasswd
      fi
   fi
fi
echo "Wifi"
## ACCÈS WIFI
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
   /usr/lib/raspberrypi-sys-mods/imager_custom set_wlan 'Gaby42' 'd08ebd2545f12ba4a9dc43eb61a9fc58b41d1c2f664dd69a555e6742169394b8' 'CN'
else
cat >/etc/wpa_supplicant/wpa_supplicant.conf <<'WPAEOF'
country=FR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
ap_scan=1

update_config=1
network={
	ssid="Gaby42"
	psk=d08ebd2545f12ba4a9dc43eb61a9fc58b41d1c2f664dd69a555e6742169394b8
}

WPAEOF
   chmod 600 /etc/wpa_supplicant/wpa_supplicant.conf
   rfkill unblock wifi
   for filename in /var/lib/systemd/rfkill/*:wlan ; do
       echo 0 > $filename
   done
fi

## DÉMARRAGE DU WIFI
systemctl start wpa_supplicant
sleep 10 # pour être certain de l'accroche du réseau wifi


## MISE À JOUR PERSO
#3 première mise à jour
#3a modification des fichiers apt pour source
#varsources=$(tail -n 1 /etc/apt/sources.list.d/raspi.list)
varsources=$(grep deb-src /etc/apt/sources.list.d/raspi.sources)
#if [ "$varsources" != "deb-src http://archive.raspberrypi.org/debian/ $DEBIAN_VER main" ]; then
if [ "$varsources" != "Types: deb deb-src" ]; then
	apt clean
#	sed -i 's/^#deb-src/deb-src/g' /etc/apt/sources.list
#	sed -i 's/^#deb-src/deb-src/g' /etc/apt/sources.list.d/raspi.list
	sed -i 's/^Types: deb/Types: deb deb-src/g' /etc/apt/sources.list.d/debian.sources
	sed -i 's/^Types: deb/Types: deb deb-src/g' /etc/apt/sources.list.d/raspi.sources
	if [ -e /etc/apt/sources.list.d/vscode.list ]; then rm /etc/apt/sources.list.d/vscode.list; fi;
fi
# #3b premières mises à jour & installations
# echo "Mises à jour du système"
# sudo apt update
# sudo apt upgrade -y
# sudo apt install locate shellcheck tree samba transmission-daemon -y

#4 Clavier & Fuseau horaire
#4a fuseau horaire
rm -f /etc/localtime
echo "Europe/Paris" >/etc/timezone
dpkg-reconfigure -f noninteractive tzdata
#4b clavier
cat >/etc/default/keyboard <<'KBEOF'
#Clavier sans fil Apple - format Macbook international
XKBMODEL="macbook79"
XKBLAYOUT="fr"
XKBVARIANT=""
XKBOPTIONS="lv3:alt_switch,grp_led:caps,caps:internal_nocancel"
BACKSPACE="guess"

KBEOF
dpkg-reconfigure -f noninteractive keyboard-configuration

#5 Configuration du disque dur
#5a Création du compte timemachine
useradd timemachine
echo timemachine:timemachine | chpasswd
#5b Création des dossiers de montage
if [ ! -d /media/WD ]; then mkdir /media/WD; fi
chown pi:pi /media/WD && chmod 1777 /media/WD
if [ ! -d /media/TimeCapsule ]; then mkdir /media/TimeCapsule; fi
chown timemachine:timemachine /media/TimeCapsule && chmod 1700 /media/TimeCapsule

#5c Récupération des UUID/PARTUUID et préparation du fichier /etc/fstab
if [ "ls -alh /dev/disk/by-uuid | awk '/sda1/ {print $9}'" = "" ]; then
		DISKPLUGGED=0;
else
		recupPART_sda
		recupUUID_sda
		PART_SDA1=$(ls -alh /dev/disk/by-partuuid | grep sda1 | awk {' print $9 '})
cat << EOF >> $firmwaredir/cmdline.txt
#console=serial0,115200 console=tty1 root=PARTUUID=$PART_SDA1 rootfstype=ext4 fsck.repair=yes rootwait quiet
EOF
		DISKPLUGGED=1;
fi
systemctl daemon-reload

## Fin du script premier démarrage
rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0