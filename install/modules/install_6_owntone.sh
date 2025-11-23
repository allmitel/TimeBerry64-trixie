#!/usr/bin/env bash

######################################
## TimeBerry Fast Install           ##
## sous-script installation Owntone ##
######################################

# v.1 - 8 février 2024 s
########################
#OK Bookworm : encours + a l'air universalisé (DEBIAN_VER)
#OK Trixie : attention la signature est caduque
#+ nécessite une "modernisation" pour l'intégration dans apt de Trixie.

#############################################################
## INSTALLATION DE SAMBA + MISE EN PLACE DES COMPTES SAMBA ##
#############################################################

install_owntone()
{
echo "> owntone in"
wget -q -O - http://www.gyfgafguf.dk/raspbian/owntone.gpg | sudo gpg --dearmor --output /usr/share/keyrings/owntone-archive-keyring.gpg
wget -q -O /etc/apt/sources.list.d/owntone.list http://www.gyfgafguf.dk/raspbian/owntone-$DEBIAN_VER.list
apt-get update > /dev/null
apt-get install owntone -qq > /dev/null
echo
echo "Mise en route de Owntone"
sudo cp $basedir/owntone.conf /etc/owntone.conf && sudo chown root:root /etc/owntone.conf && sudo chmod 644 /etc/owntone.conf
sudo systemctl enable owntone
sudo systemctl disable owntone

if [ $DISKPLUGGED = 1 ]; then service owntone start; fi
echo "> owntone done"
}