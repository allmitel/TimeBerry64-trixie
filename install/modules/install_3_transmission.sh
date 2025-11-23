#!/usr/bin/env bash

###########################################
## TimeBerry Fast Install                ##
## sous-script installation Transmission ##
###########################################

# v.1 - 8 février 2024
######################
# updt : CHECK TRIXIE - novembre 2025

#############################################################
## INSTALLATION DE SAMBA + MISE EN PLACE DES COMPTES SAMBA ##
#############################################################

install_transmission()
{
echo
echo "######################################"
echo "## Installation Transmission-daemon ##"
echo "######################################"

apt-get install transmission-daemon -qq > /dev/null

systemctl enable transmission-daemon
systemctl disable transmission-daemon && sudo service transmission-daemon stop

sudo cp $basedir/transmission-daemon/settings.json /etc/transmission-daemon/settings.json && sudo chown debian-transmission:debian-transmission /etc/transmission-daemon/settings.json && sudo chmod 600 /etc/transmission-daemon/settings.json

if [ $DISKPLUGGED = 1 ]; then
	if [ ! -d /media/WD/Raspberry ]; then mount /dev/sda3; fi
	if [ -d /var/lib/transmission-daemon ]; then mv /var/lib/transmission-daemon /var/lib/transmission-daemon.bak; fi

	if [ -d /media/WD/Raspberry/archive-transmission ]; then
		cp /media/WD/Raspberry/archive-transmission/transmission-daemon.tar.bz2 /var/lib/
		cd /var/lib
		tar -xf /var/lib/transmission-daemon.tar.bz2
		rm /var/lib/transmission-daemon.tar.bz2

		chown debian-transmission:debian-transmission /media/WD/.transmission-temp && chmod 1700 /media/WD/.transmission-temp
		chown debian-transmission:debian-transmission /media/WD/Downloads/torrents && chmod 1777 /media/WD/Downloads/torrents;
	fi;
else
	echo "Le disque WD n'est actuellement pas accessible"
	echo "> il faudra restituer la sauvegarde Transmission manuellement";
fi
}