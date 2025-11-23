#!/bin/bash

echo "Nuke TM"
SMBD_OFF_VERIF=$(/usr/sbin/service smbd status | grep running | awk '{print $3}')
TESTMOUNT=$(lsblk | grep sda2 | awk '{print $7}')
cd ~
if [ ! -z $SMBD_OFF_VERIF ]; then
	echo "Le service smbd est en route, il faut l'éteindre d'abord"
	sudo /usr/sbin/service smbd stop
	echo "wait"
	sleep 5;
fi

if [ ! -z $TESTMOUNT ]; then
	echo "La partition contenant TimeCapsule est montée"
	echo "il faut d'abord la détacher"
	sudo umount /dev/sda2
	echo "wait"
	sleep 5;
fi

echo
echo

while true
do
read -r -p "On continue ? [O/N] " input
	case $input in
	[oO])

HDDPART_UUID=$(ls -alh /dev/disk/by-uuid/ | grep sda2 | awk '{print $9}')
HDDPART_LABEL=$(ls -alh /dev/disk/by-label/ | grep sda2 | awk '{print $9}')

sudo mkfs.ext4 -L $HDDPART_LABEL -U $HDDPART_UUID -F /dev/sda2
sudo mount /dev/sda2
sudo chown -R timemachine:timemachine /media/TimeCapsule
sudo chmod -R 1700 /media/TimeCapsule

sudo /usr/sbin/service smbd start
exit 0
break
;;
	[nN])

echo "On arrête là"
echo "la partition /dev/sda2 est démontée"
echo "le service smbd reste éteint"
exit 0
break
;;

	*)

echo "> erreur : il faut choisir [O/N] "
echo
;;

	esac
done
