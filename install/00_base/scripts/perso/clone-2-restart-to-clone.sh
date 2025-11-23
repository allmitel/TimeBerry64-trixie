#!/bin/bash
########
## Redémarrage auto vers Clone
## > avril 2024
## rev0.01
## rev0.02 - 11 octobre 2024 - corrections universalisation
## rev0.03 - mai 2025

##UNIVERSALISATION
DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
if [ "$DEBIAN_VER" == "bullseye" ]; then firmwaredir="/boot/";
elif [ "$DEBIAN_VER" == "bookworm" ]; then firmwaredir="/boot/firmware/";
else
        echo "Erreur de script"
        exit 0;
fi


##VARIABLES
SDPART=$(ls -alh /dev/disk/by-partuuid/ | grep mmcblk0p2 | awk '{print $9}')
HDDPART=$(ls -alh /dev/disk/by-partuuid/ | grep sda1 | awk '{print $9}')
STRING_SD=$(grep "$SDPART" $firmwaredir/cmdline.txt | sed 's/#//')
STRING_HDD=$(grep "$HDDPART" $firmwaredir/cmdline.txt | sed 's/#//')
BOOTABLE=0
if [ "$STRING_HDD" == "" ];then
	STRING_HDD=$(echo "$STRING_SD" | sed -e "s/$SDPART/$HDDPART/");
fi

##FONCTIONS
check_clone() {
PATH_CLONE=$(lsblk | grep sda1 | awk '{print $7}')
if [ "$PATH_CLONE" == "" ]; then
	sudo mkdir /TEMPO_CLONE
	sudo mount /dev/sda1 /TEMPO_CLONE
	PATH_CLONE=$(lsblk | grep sda1 | awk '{print $7}');
fi
if [ ! -e $PATH_CLONE/home/pi/.config/.syshdd ]; then
	echo "Le clone apparaît incorrect"
	echo "Pas de redémarrage immédiat possible"
	BOOTABLE=0;
else
	echo "Le clone semble OK"
	echo "Redémarrage possible"
	BOOTABLE=1;
fi
sudo umount /dev/sda1
if [ -d /TEMPO_CLONE ]; then sudo rm -R /TEMPO_CLONE; fi
export BOOTABLE
}

###############################################################################################
###############################################################################################
###############################################################################################
##DÉBUT DU SCRIPT
echo "#############################################"
echo "# TIMEBERRY64                               #"
echo "# Redémarrage auto vers partition /dev/sda1 #"
echo "#############################################"
echo
##VÉRIFICATION
if [ ! -e /home/pi/.config/.firstclonedone ]; then
        echo "Le premier clone de ce système n'a pas été fait correctement :"
	check_clone
	if [ "$BOOTABLE" = 1 ]; then
		echo "Attention c'est peut-être un clone ancien"
		echo "Redémarrage incertain";
	fi;
else
	check_clone;
fi

##FICHIERS DE REDÉMARRAGE
if [ ! -e $firmwaredir/cmdline.hdd ]; then
	cp $firmwaredir/cmdline.txt $firmwaredir/cmdline.sd
	cp $firmwaredir/cmdline.txt $firmwaredir/cmdline.hdd
	sudo sed -i "s/$STRING_SD/#$STRING_SD/" $firmwaredir/cmdline.hdd
        echo "$STRING_HDD" >> $firmwaredir/cmdline.hdd;
fi
echo "> vérif du fichier de redémarrage"
echo "########################"
cat $firmwaredir/cmdline.hdd
echo "########################"
while true
do
read -r -p "Est ce que c'est bon? [O/n] " input
	case $input in
		[oO])
			cp $firmwaredir/cmdline.hdd $firmwaredir/cmdline.txt
			if [ "$BOOTABLE" = 1 ]; then
				echo
				echo "Redémarrage dans 5 secondes"
				sleep 5
				sudo reboot;
			else
				echo
				echo "Le clone n'a pas été identifié comme bootable"
				echo "On s'arrête là"
				echo "ATTENTION : le système est prêt à redémarrer sur le clone!"
				echo "vérifier $firmwaredir/cmdline.txt avant de relancer!"
#				exit 0;
			fi
		break
		;;

		[nN])
			echo
			echo "Le fichier /boot/cmdline.hdd n'est pas correct - rien ne change"
			echo "On s'arrête là"
#			exit 0
		break
		;;

		*)
			echo
			echo "erreur"
		break
		;;

	esac
done
#MISE EN PLACE D'UN REBOOT AUTOMATIQUE - UNIQUEMENT ACTIVÉ PAR CRONTAB = EN CAS D OUBLI DE REBOOT SUR SD
sudo bash -c "echo '1' > /boot/firmware/install/.rebootflag"
exit 0
