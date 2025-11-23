#!/bin/bash
########
## Backup vers /dev/sda1
## > Attention à la commande rsync qui DOIT effacer les fichiers en trop
## > pour avoir un système stable/complet/fonctionnel
## > mai 2025
##rev0.02
HDDPART_UUID=$(ls -alh /dev/disk/by-uuid/ | grep sda1 | awk '{print $9}')
HDDPART_LABEL=$(ls -alh /dev/disk/by-label/ | grep sda1 | awk '{print $9}')
TEMPODIR=/tempo

##UNIVERSALISATION
DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
if [ $DEBIAN_VER == "bullseye" ]; then firmwaredir=/boot/;
elif [ $DEBIAN_VER == "bookworm" ]; then firmwaredir=/boot/firmware/;
else
        echo "Erreur de script : DEBIAN_VER=$DEBIAN_VER"
        exit 0;
fi

##DÉBUT DU SCRIPT
echo "#################################################"
echo "# Backup du système vers la partition /dev/sda1 #"
echo "# + retouche /etc/fstab                         #"
echo "#################################################"
echo
cd /
sleep 1
echo "> tests pour savoir si l'environnement de fonctionnement est adequat"
if [ -e /home/pi/.config/.syshdd ]; then
	echo "   système lancé sur /dev/sda1"
	echo "   > on doit s'arrêter là"
	exit 0;
fi

if [ -d $TEMPODIR ]; then
	echo "   le dossier /tempo existe déjà : c'est trop risqué de monter /dev/sda1 dessus"
	echo "   on pourrait écraser bêtement des fichiers importants"
	TEMPODIR=/tempo-joker
	sudo mkdir $TEMPODIR;
else
	sudo mkdir $TEMPODIR;
fi

if [ ! -e /home/pi/.config/.firstclonedone ]; then
	echo "> Premier Clone : il faut effacer le disque /dev/sda1"

		##VÉRIFICATION QUE LA PARTITION /dev/sda1 N'EST PAS MONTÉE
		TESTMOUNT=$(lsblk | grep sda1 | awk '{print $7}')
		if [ ! -z $TESTMOUNT ]; then
		        echo "La partition est montée : on ne peut pas immédiatement la nettoyer avant backup";
			echo "> démontage"
			sudo umount /dev/sda1
			echo "Le Point de montage était : $TESTMOUNT"
			while true
			do
				read -r -p "Est-ce qu'on efface ce dossier de montage ? [O/n] " input
				case $input in
					[oO])
						echo "> effacement du point de montage"
						sudo rm -R $TESTMOUNT
						break
					;;

					[nN])
						echo "> on le laisse"
						break
					;;

					*)
						echo "Erreur : taper [O/n]"
					;;
				esac
			done;
		fi


	sudo mkfs.ext4 -L $HDDPART_LABEL -U $HDDPART_UUID -F /dev/sda1
	echo "> effaçage fait";
fi
sudo mount /dev/sda1 $TEMPODIR

if [ ! -d /home/pi/.config ]; then mkdir /home/pi/.config; fi
touch /home/pi/.config/.firstclonedone
sudo rsync -axAXUv --delete-delay / $TEMPODIR
echo
echo "Copie faite"
echo
## Nettoyage final et préparation au lancement sur /dev/sda1

#backup de fstab + manipulation pour préparer un fstab correct pour un lancement sur /dev/sda1
if [ ! -e $TEMPODIR/etc/fstab.hdd ]; then
        sudo cp $TEMPODIR/etc/fstab $TEMPODIR/etc/fstab.sd
        sudo cp $TEMPODIR/etc/fstab $TEMPODIR/etc/fstab.hdd
        var=$(sudo sed -n 3p $TEMPODIR/etc/fstab.hdd | awk '{print $1}')
        sudo sed -i "s/$var/#$var/" $TEMPODIR/etc/fstab.hdd
        sudo sed -i 's/#PARTUUID=079e0442-dc66-944d-b4d3-f1b75257d048/PARTUUID=079e0442-dc66-944d-b4d3-f1b75257d048/' /tempo/etc/fstab.hdd;
fi
#une fois manip faite, préparation pour lancement sur /dev/sad1
sudo cp $TEMPODIR/etc/fstab.hdd $TEMPODIR/etc/fstab

#nettoyage sur /dev/sda1
sudo rm -R $TEMPODIR$TEMPODIR
#flag de lancement sur /dev/sda1
touch $TEMPODIR/home/pi/.config/.syshdd
touch $TEMPODIR/home/pi/SYSTÈME-SUR-PARTITION-SDA1

#nettoyage sur /dev/mmcblk0p2
sudo umount /dev/sda1
sudo rm -R $TEMPODIR

echo
echo "Verif du disque"
result=$(sudo fsck.ext4 -fy /dev/sda1) && echo "$result"
#valeur=$(echo "$result" | grep "non-contiguous" | awk '{sub(/\(/,"");sub(/\%/,""); print $4}')
#valeur100=$($valeur * 100)
#echo "$valeur100"
#if [ $valeur100 -ge 100 ]; then
#	sudo mount /dev/sda1
#	sudo e4defrag /dev/sda1
#	sudo umount /dev/sda1;
#fi
exit 0