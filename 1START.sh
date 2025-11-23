#!/usr/bin/env bash

	#######################################################
	# Primo nettoyage/installation des raspberry          #
	# rev. novembre 2025 objectif : toutes versions 32/64 #
	# vers un fonctionnement au maximum agnostique        #
	# bullseye & bookworm                                 #
	# + novembre 2025 - adaptations TRIXIE + Gaby42       #
	#######################################################

### Description :
# Script de primo installation du système - unifié pour ne pas avoir à maintenir un tas
# de dossier différent en fonction des types d'installation et pour avoir une base
# unifiée pour la compilation

### Changelog :
# V2 : refactoring complet autour de scripts secondaires + un seul script de démarrage + nettoyage
## 16 mai : en cours sortie de la prise en compte 
## des sources
## des premiers install et update
## du disque dur (cpt timemachine + dossier + fstab)
## 20 juin 2025 - check wifi/hotspot pour inversion carte (4G/5G sur externe)
## 16 novembre 2025 - check et adaptations pour Trixie

### Todo :
#	sysctl-trixie.conf
#

##########################################################################################
## VARIABLES

## Dossiers de base
USER=${SUDO_USER:-$(who -m | awk '{ print $1 }')}
homedir=/home/$USER
firmwaredir="$(dirname "$0")"
firmwaredir="$(cd "$firmwaredir" && pwd)"
scriptdir="$(cd "$firmwaredir/install" && pwd)"
basedir=$scriptdir/00_base

export homedir
export scriptdir
export basedir

## Pour tests raspi-config
ASK_TO_REBOOT=0
CONFIG=$firmwaredir/config.txt
CMDLINE=$firmwaredir/cmdline.txt
DISKPLUGGED=0
export CONFIG
export CMDLINE
export DISKPLUGGED

## SOURCE DES SCRIPTS SUPPLÉMENTAIRES ET FONCTIONS SUPPORT
#cd $(pwd)
#source "./install/modules/install_test.sh"
source "./install/modules/script_functions.sh"
source "./install/modules/install_1_sources.sh"
source "./install/modules/install_2_base.sh"
source "./install/modules/install_3_transmission.sh"
source "./install/modules/install_4_samba.sh"
source "./install/modules/install_5_hotspot_gaby42.sh"
source "./install/modules/install_6_owntone.sh"

DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
export DEBIAN_VER
# Possibilité "bullseye" ou "bookworm" ou "trixie" >> "trixie" 
##########################################################################################

#######################
#######################
##  DÉBUT DU SCRIPT  ##
#######################
#######################

echo "############################################################"
echo "##        RASPBERRYPI - 1START - PREMIER LANCEMENT        ##"
echo "##                 novembre 2025 'rapide'                 ##"
echo "############################################################"
sleep 2
echo
echo "## Test pour savoir si le script est lancé en utilisateur sudo"
echo
CHECK_SUDO
echo "> OK"
echo

echo "## Nettoyage de la carte SD"
echo
if [ -d $firmwaredir/.Spotlight-V100 ]; then rm -R $firmwaredir/.Spotlight-V100; fi
if [ -d $firmwaredir/.fseventsd ]; then rm -R $firmwaredir/.fseventsd; fi
if [ -d $firmwaredir/.TemporaryItems ]; then rm -R $firmwaredir/.TemporaryItems; fi
if [ -d $firmwaredir/.Trashes ]; then rm -R $firmwaredir/.Trashes; fi
cd $firmwaredir
find \( -name ".DS_Store" -or -name ".Trashes" -or -name "._*" -or -name ".TemporaryItems" \) -delete
echo
echo "> Nettoyage fait"
echo

echo "## Copie et installation scripts & réglages divers"
echo
cp $basedir/nsswitch.conf /etc/nsswitch.conf && chown root:root /etc/nsswitch.conf && chmod 644 /etc/nsswitch.conf
# cp $basedir/keyboard /etc/default/keyboard && chown root:root /etc/default/keyboard && chmod 644 /etc/default/keyboard
cp $basedir/pi.bashrc $homedir/.bashrc && chown pi:pi $homedir/.bashrc && chmod 755 $homedir/.bashrc
cp $basedir/root.bashrc /root/.bashrc && chown root:root /root/.bashrc && chmod 755 /root/.bashrc
cp $basedir/wifi/*.bin /usr/lib/firmware/mediatek/
echo
echo "> fichiers installés"
echo

echo "## Copie des scripts personnels"
echo
cp $basedir/scripts/system/*.sh /etc && chown root:root /etc/renaud*.sh && chmod 1755 /etc/renaud*.sh
cp -R $basedir/scripts/perso $homedir/.scripts && chown -R pi:pi $homedir/.scripts && chmod 1755 $homedir/.scripts && chmod 1555 $homedir/.scripts/*.sh
echo
echo "> scripts système et perso installés"
echo

##NOTE : rendu inutile par le script firstrun.sh

# echo
# echo "####################################################"
# echo "## Préparation pour branchement disque externe +  ##"
# echo "##                 partage Samba                  ##"
# echo "####################################################"
# echo
# 
# echo "#1 Création du compte timemachine"
# useradd timemachine
# echo timemachine:timemachine | chpasswd
# echo "> compte timemachine créé"
# echo
# echo "#2 Création des dossiers utiles pour le partage Samba"
# if [ ! -d /media/WD ]; then mkdir /media/WD; fi
# chown pi:pi /media/WD && chmod 1777 /media/WD
# if [ ! -d /media/TimeCapsule ]; then mkdir /media/TimeCapsule; fi
# chown timemachine:timemachine /media/TimeCapsule && chmod 1700 /media/TimeCapsule
# echo
# echo "> dossiers créés"
# echo
# echo "#3 Préparation pour connexion du disque externe / manipulation du fichier fstab"
# echo "> test de la présence du disque"
# if [ "ls -alh /dev/disk/by-uuid | awk '/sda1/ {print $9}'" = "" ]; then
# 	echo "le disque n'est pas branché !";
# else
# 	echo " Le disque est branché, on continue "
# 	echo " Prise en compte des partitions habituelles de partage "
# 	recupPART_sda
# 	echo
# 	echo " Récupération des données pour une référence ultérieure "
# 	recupUUID_sda
# cat << EOF >> $firmwaredir/cmdline.txt
# 
# #console=serial0,115200 console=tty1 root=PARTUUID=34fdce00-e067-3940-a8cc-c420599dc213 rootfstype=ext4 fsck.repair=yes rootwait quiet
# EOF
# 	DISKPLUGGED=1;
# fi
# 
# ## POUR PRISE EN COMPTE DU NOUVEAU /etc/fstab
# systemctl daemon-reload
# 
# install_repo_sources
#install_base "install_vulkan_deps"
install_base
install_transmission
install_samba
install_hotspot
install_owntone

echo "#4 Préparation pour installation future"
echo
if [ -s $scriptdir/2START.sh ]; then
		mv $scriptdir/2START.sh /home/pi/
		chown pi:pi $homedir/2START.sh
		chmod +x $homedir/2START.sh;
	else
		echo "Le script nécessaire pour poursuivre n'est pas trouvé."
		echo
		echo " > il faudra le retrouver manuellement.";
fi
echo


echo
echo "#######################################"
echo "## Copie et préparation pour Crontab ##"
echo "#######################################"
echo
echo "Modification de /etc/crontab"
if [ -e $homedir/crontab-temp ]; then
	mv $homedir/crontab-temp $homedir/crontab-temp.bak;
fi
cp /etc/crontab $homedir/crontab-temp
chown pi:pi $homedir/crontab-temp && chmod 777 $homedir/crontab-temp
sed -n 5,21p $basedir/crontab.source >> $homedir/crontab-temp
mv $homedir/crontab-temp /etc/crontab
chown root:root /etc/crontab && chmod 644 /etc/crontab
echo "> Fait"





# echo
# echo "####################"
# echo "## RASPI - CONFIG ##"
# echo "####################"
# echo
# echo "Installation Semi-automatique"
# 
# raspi-config nonint do_memory_split 256
# raspi-config nonint do_change_timezone Europe/Paris
# raspi-config nonint do_wifi_country FR
# raspi-config nonint do_hostname TimeBerry64 # à la fin pour pas casser l'installation

###
## Installation pour préserver la carte SD
###
# ## 1- Manipulation fstab
# sudo cat << EOF >> /etc/fstab
# 
# ## MINIMISER L'USURE DE LA CARTE SD
# tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
# tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
# #utilisation de log2ram à la place : https://github.com/azlux/log2ram
# #tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0
# EOF
## 2- Log2ram
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
sudo wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
sudo apt update
sudo apt install log2ram
##

echo "####################"
echo "## FIN            ##"
echo "####################"
echo
cp $basedir/to_do.txt $homedir/
updatedb

if [ $ASK_TO_REBOOT = 1 ]; then
	echo "Tout fini : redémarrage"
	sleep 5
	echo "encore 5 secondes"
	sleep 5
	echo
	reboot;
else
	echo "Tout fini"
	exit 0;
fi
