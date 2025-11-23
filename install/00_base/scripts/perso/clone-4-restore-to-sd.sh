#!/bin/bash
##rev0.02
## mai 2025

##UNIVERSALISATION
DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
if [ $DEBIAN_VER == "bullseye" ]; then firmwaredir=/boot/;
elif [ $DEBIAN_VER == "bookworm" ]; then firmwaredir=/boot/firmware/;
else
        echo "Erreur de script"
        exit 0;
fi
TEMPODIR=/tempo-restore-to-sd

##DÉBUT DU SCRIPT
echo "#########################################################"
echo "# Restoration de clone de /dev/sda1 vers /dev/mmcblk0p2 #"
echo "#########################################################"
echo
cd /
echo "D'abord on vérifie si on est bien sur lancé sur la partition extérieure"
#bootpart=$(lsblk | grep /$ | cut -c7-10)
#echo $bootpart
#if [ $bootpart != "sda1" ];then
if [ ! -e /home/pi/.config/.syshdd ]; then
        echo "TimeBerry64 n'est pas lancé sur la partition /dev/sda1"
        echo "On arrête là"
        exit 0;
else
        echo "TimeBerry64 est bien lancé sur la partition /dev/sda1"
        echo "On peut continuer"
        sleep 2;
fi


if [ ! -d $TEMPODIR ];then sudo mkdir $TEMPODIR; fi
sudo mount /dev/mmcblk0p2 $TEMPODIR
sudo rsync -axAXUv --delete-delay / $TEMPODIR
echo
echo "Copie faite"
echo
#nettoyage sur la partition restaurée
sudo cp $TEMPODIR/etc/fstab.sd $TEMPODIR/etc/fstab
sudo rm $TEMPODIR/home/pi/.config/.syshdd
sudo rm -R $TEMPODIR$TEMPODIR
sudo mv $TEMPODIR/home/pi/SYSTÈME-SUR-PARTITION-SDA1 $TEMPODIR/home/pi/SYSTÈME-RESTAURÉ-SUR-SD

#nettoyage sur la partition système montée
sudo umount $TEMPODIR
sudo rm -R $TEMPODIR

#préparation pour redémarrage
sudo cp $firmwaredir/cmdline.sd $firmwaredir/cmdline.txt

echo "Redémarrage sur la partition /dev/mmcblk0p2"
echo "Encore 10 secondes"
sudo sleep 10
echo "Encore 5 secondes"
sudo sleep 5
echo "See you over the restart..."
sudo reboot
exit 0
