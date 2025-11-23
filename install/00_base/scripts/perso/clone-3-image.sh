#!/bin/bash
########
## Image de /dev/mmcblk0 vers //media/WD/altra•Docs/images/image.img
## > mai 2025
##rev0.02

VARMACHINE=$(hostname)
VARDATE=$(date +%Y-%m-%d)
DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
export DEBIAN_VER
TEMPODIR=/tempo-image

echo "Tests préalables :"
if test $DEBIAN_VER != "bookworm"; then exit 0; fi

if [ ! -e /home/pi/.config/.syshdd ]; then
	echo "Le système n'est pas lancé à partir de la partition /dev/sda1"
	echo "On ne peut continuer"
	exit 0;
fi

if [ ! -e /boot/firmware/cmdline.sd ]; then
	echo 'Le script est lancé sans que tous les éléments nécessaires soient en place'
	echo 'Erreur fatale : on arrête'
	exit 0;
fi
echo ">OK"
echo
sleep 1

echo "Copies de fichiers pour préparer  le redémarrage :"
sudo cp /boot/firmware/cmdline.sd /boot/firmware/cmdline.txt
echo ">OK"
echo
sleep 1

echo "Copies d'éléments pour préparer le backup :"
if [ ! -d $TEMPODIR ]; then sudo mkdir $TEMPODIR; fi
sudo mount /dev/mmcblk0p2 $TEMPODIR

if [ ! -e /usr/local/bin/pishrink.sh ]; then
	cd /usr/local/bin
	curl -LO https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
	sudo chmod +x /usr/local/bin/pishrink.sh
	sudo cp /usr/local/bin/pishrink.sh $TEMPODIR/usr/local/bin/pishrink.sh;
fi

if [ ! -d /media/WD/altra•Docs/Images ]; then
	echo "> création du dossier d'archivage des images nécessaire"
	mkdir /media/WD/altra•Docs/Images;
fi
echo ">OK"
echo
sleep 1

echo "Vérifications sur la carte SD :"
sudo e4defrag /dev/mmcblk0p1
sudo e4defrag /dev/mmcblk0p2
sudo umount /dev/mmcblk0p1
sudo umount /dev/mmcblk0p2
sudo fsck.msdos -fy /dev/mmcblk0p1
sudo fsck.ext4 -fy /dev/mmcblk0p2
echo ">OK"
echo
sleep 1

echo "Backup :"
echo ">copie"
sudo dd if=/dev/mmcblk0 of=/media/WD/altra•Docs/Images/$VARMACHINE-$VARDATE.img bs=1M status=progress
cd /media/WD/altra•Docs/Images/
echo ">compression"
sudo /usr/local/bin/pishrink.sh /media/WD/altra•Docs/Images/$VARMACHINE-$VARDATE.img
sudo pbzip2 /media/WD/altra•Docs/Images/$VARMACHINE-$VARDATE.img
echo ">all done"
sudo rm -R $TEMPODIR

exit 0
