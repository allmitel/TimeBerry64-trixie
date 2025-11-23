#!/usr/bin/sh

#######################################################################
## AUTOREBOOT                                                        ##
## -> check de la présence du flag .rebootflag                       ##
## 	- création du flag sinon                                     ##
##                                                                   ##
## -> si positif                                                     ##
##	- check de la présence d'un fichier de boot correct cmdline  ##
##	- changement de la valeur du flag .rebootflag                ##
##	- reboot                                                     ##
#######################################################################
## Lancement quotidien par /etc/crontab à 2h00 ##
## > V.00 - 21 mars 2025                       ##
#################################################

############
## CHANGELOG
# 21 mars 2025

############
## VARIABLES
do_reboot=0

############
## FONCTIONS

#####################
## DEBUT DU SCRIPT ##
#####################

## test si la partition boot est bien montée (éventualité préparation d'image)
test_firmware_monte=$(lsblk | grep "mmcblk0p1" | awk '{print $7}')
if [ "$test_firmware_monte" = "" ]; then
	echo "La partition mmcblk0p1 semble ne pas être montée"
	sudo mount /dev/mmcblk0p1
	sleep 10;
fi

## test de l'existence du flag .rebootflag
if [ ! -e /boot/firmware/install/.rebootflag ]; then
	sudo bash -c "echo '0' > /boot/firmware/install/.rebootflag";
fi

## test de l'existence du fichier cmdline.sd et transformation adéquate
if [ ! -e /boot/firmware/cmdline.sd ]; then
	if [ ! -e /boot/firmware/cmdline.hdd ]; then
		sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.sd;
	else
		echo "Erreur : configuration incohérente\nle fichier cmdline.sd n'existe pas alors qu'il le devrait"
		exit 0;
	fi;
else
	sudo cp /boot/firmware/cmdline.sd /boot/firmware/cmdline.txt;
fi

## test de redémarrage, désarmement du système et redémarrage effectif
do_reboot=$(cat /boot/firmware/install/.rebootflag)

if [ "$do_reboot" = 1 ]; then
	sudo bash -c "echo '0' > /boot/firmware/install/.rebootflag"
	sudo reboot;
else
	exit 0;
fi