#!/bin/bash
##rev0.01
echo '#############################################'
echo '# Éjection des disque durs avant extinction #'
echo '#############################################'
echo
sleep 1
echo "Extinction des services qui pourraient utiliser les HDD"
sudo service smbd stop
sudo service transmission-daemon stop
echo "done"
echo
sleep 5
echo "Démontage des disques"
cd /home/$USER
sudo umount /dev/sda2
sudo umount /dev/sda3
echo "done"
echo
sleep 5
echo "HDD Poweroff"
#sudo hdparm -Y /dev/sda
sudo udisksctl power-off -b /dev/sda
echo
echo "done"