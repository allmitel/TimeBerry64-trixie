#!/usr/bin/env bash

####################################
## TimeBerry Fast Install         ##
## sous-script installation Samba ##
####################################

# v.1 - 8 février 2024 s
########################
#OK Bookworm : encours

#############################################################
## INSTALLATION DE SAMBA + MISE EN PLACE DES COMPTES SAMBA ##
#############################################################

install_samba()
{
echo
echo "######################################"
echo "## Compilation & Installation Samba ##"
echo "######################################"

apt-get install samba -qq > /dev/null
systemctl disable smbd
cp $basedir/samba/smb.conf /etc/samba/smb.conf && chown root:root /etc/samba/smb.conf && sudo chmod 644 /etc/samba/smb.conf
echo
echo "Création du compte samba 'pi'"
smbpasswd -a pi
echo
echo "Création du compte samba 'timemachine'"
smbpasswd -a timemachine
echo
echo "> samba done"
}