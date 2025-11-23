#!/usr/bin/env bash

##
## rev. fev 2024 : nettoyage des fonctions inutiles
## utilisation de raspi-config plutôt que récup les fonctions
##

## fonctions source
#######################################################
## FONCTION POUR VÉRIFIER QU'ON DÉMARRE BIEN EN SUDO ##
#######################################################
CHECK_SUDO() {
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Ce script doit être lancé à partir de l'utilisateur root. Try 'sudo $0'"
    exit 1
fi
}


##############################################
## Fonctions de manipulation des partitions ##
##############################################
## Attention ces deux fonctions vont par paire : source > fstab-int > fstab-final > installation
recupPART_sda() {
	
		# Gestion d'un éventuelle manipulation avant qui aurait échoué
		
if [[ -e $homedir/fstab-temp ]]; then
	mv $homedir/fstab-temp $homedir/fstab-temp.bak;
fi
				
		# Copie des données fstab d'origine / Création du fichier de manip

cp /etc/fstab $homedir/fstab-temp
chown pi:pi $homedir/fstab-temp && chmod 777 $homedir/fstab-temp
	
		# Manipulation du fichier fstab
if [[ -e $basedir/fstab.source ]]; then
	sed -n 7,19p $basedir/fstab.source >> $homedir/fstab-temp
	echo;
		# Si pas de préversion
else
	local varpartuuidsda1=$(ls -alh /dev/disk/by-partuuid | awk '/sda1/ {print $9}')
	local varuuidsda2=$(ls -alh /dev/disk/by-uuid | awk '/sda2/ {print $9}')
	local varuuidsda3=$(ls -alh /dev/disk/by-uuid | awk '/sda3/ {print $9}')
#
cat << EOF >> $homedir/fstab-temp			 

#Système sur disque externe WD - sda1 : NON MONTÉ !!!
#PARTUUID=$varpartuuidsda1   /       ext4    defaults,noatime        0       1


#OPTION EXT4 - Disque WD My Passport
#/dev/sda2 Pour TimeCapsule
UUID=$varuuidsda2       /media/TimeCapsule      ext4    rw,nosuid,noauto 0 0
#/dev/sda3 Pour partage & Transmission
UUID=$varuuidsda3       /media/WD  ext4    rw,nosuid,noatime,noauto 0 0

EOF
#			
	echo;
fi
}


recupUUID_sda() {
if [[ -e $basedir/fstab.source ]]; then
	echo "Un fichier sauvegarde a été trouvé : simple copie des données"
	sed -n 20,31p $basedir/fstab.source >> $homedir/fstab-temp
	echo;
else
	echo "Aucun fichier de sauvegarde a été trouvé : il faut rechercher"
	echo
	echo "> récupération des données SSID / UUID des disques :"
	echo
cat << EOF >> $homedir/fstab-temp

##
## Récupération automatique des différents UUID/PARTUUID des partitions de /dev/sda
## Pour référence :
##

EOF
## TODO : faire une boucle pour automatiser la manip
echo "Partition /dev/sda1 - en principe clone-système"
local varlabelsda1=$(ls -alh /dev/disk/by-label | awk '/sda1/ {print $9}')
local varuuidsda1=$(ls -alh /dev/disk/by-uuid | awk '/sda1/ {print $9}')
local varpartuuidsda1=$(ls -alh /dev/disk/by-partuuid | awk '/sda1/ {print $9}')
echo "## Partition sda1 — "$varlabelsda1" ##" >> $homedir/fstab-temp
echo "## UUID         "$varuuidsda1 >> $homedir/fstab-temp
echo "## PARTUUID     "$varpartuuidsda1 >> $homedir/fstab-temp
echo "" >> $homedir/fstab-temp
echo "Partition /dev/sda2 - en principe timemachine"
local varlabelsda2=$(ls -alh /dev/disk/by-label | awk '/sda2/ {print $9}')
local varuuidsda2=$(ls -alh /dev/disk/by-uuid | awk '/sda2/ {print $9}')
local varpartuuidsda2=$(ls -alh /dev/disk/by-partuuid | awk '/sda2/ {print $9}')
echo "## Partition sda2 — "$varlabelsda2" ##" >> $homedir/fstab-temp
echo "## UUID         "$varuuidsda2 >> $homedir/fstab-temp
echo "## PARTUUID     "$varpartuuidsda2 >> $homedir/fstab-temp
echo "" >> $homedir/fstab-temp
echo "Partition /dev/sda3 - en principe partage"
local varlabelsda3=$(ls -alh /dev/disk/by-label | awk '/sda3/ {print $9}')
local varuuidsda3=$(ls -alh /dev/disk/by-uuid | awk '/sda3/ {print $9}')
local varpartuuidsda3=$(ls -alh /dev/disk/by-partuuid | awk '/sda3/ {print $9}')
echo "## Partition sda3 — "$varlabelsda3" ##" >> $homedir/fstab-temp
echo "## UUID         "$varuuidsda3 >> $homedir/fstab-temp
echo "## PARTUUID     "$varpartuuidsda3 >> $homedir/fstab-temp
echo "" >> $homedir/fstab-temp
echo
echo "Les partitions ont été trouvées et copiées"
echo;
fi
## Gestion de la sauvegarde du fichier originel /etc/fstab
echo
echo "Sauvegarde du fichier originel"
if [[ -e /etc/fstab.bak ]]; then
	if [[ -e /etc/fstab.bak2 ]]; then
		mv /etc/fstab.bak2 /etc/fstab.bak3;
	fi
	mv /etc/fstab.bak /etc/fstab.bak2;
fi
mv /etc/fstab /etc/fstab.bak
echo
sleep 1
echo "Fichier /etc/fstab modifié : vérification"
cat $homedir/fstab-temp
echo
echo
while true
        	do
                	read -r -p "C'est OK ? [O/n] " input
	                case $input in
        	                [oO][uU][iI]|[oO]|[yY])
                	                echo "Installation du fichier fstab transformé"
									mv $homedir/fstab-temp /etc/fstab
									chown root:root /etc/fstab && sudo chmod 644 /etc/fstab
									rm /etc/fstab.bak
									echo "> done"
									echo
									cd $homedir
									if [ -e $homedir/fstab-result ]; then sudo rm $homedir/fstab-result; fi
									if [ -e $homedir/fstab-result.bak ]; then sudo rm $homedir/fstab-result.bak; fi
									ASK_TO_REBOOT=1
        	        	break
                		;;
                        	[nN][oO][nN]|[nN])
                                	echo "On ne change rien, il faudra changer /etc/fstab manuellement"
                                	echo "> ~/fstab-result et ~/fstab-temp pour référence"
                                	ASK_TO_REBOOT=0
                break
                ;;
                        *)
                                echo "erreur - c'est (O)ui ou (N)on"
                ;;
                esac
        done
}
