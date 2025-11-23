#!/bin/bash
##rev0.01
echo '###########################'
echo '## HDD Cleanup Script V1 ##'
echo '###########################'
echo

defragFCT() {
sudo e4defrag /dev/sda2
sudo e4defrag /dev/sda3
}


sleep 1
echo "Extinction des services qui pourraient utiliser les HDD"
sudo service smbd stop
sudo service transmission-daemon stop
echo "> done"
echo
sleep 1
echo "Démontage des disques"
sudo umount /dev/sda2
sudo umount /dev/sda3
echo "> done"
echo
sleep 1
echo "Commande de nettoyage des disques"
sudo fsck.ext4 -fy /dev/sda2
echo
sudo fsck.ext4 -fy /dev/sda3
echo "> done"
echo
echo "Remise en route des partages"
sudo mount /dev/sda2
sudo mount /dev/sda3
case "$1" in
	defrag)
		echo "Défragmentation des partitions externes - attention c'est long"
		defragFCT
	;;
esac
sleep 1
sudo service smbd restart
sleep 1
sudo service transmission-daemon restart
echo "> done"
echo
sleep 1
echo " All Done > fin "
