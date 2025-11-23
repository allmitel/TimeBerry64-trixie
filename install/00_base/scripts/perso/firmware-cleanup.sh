#!/bin/bash
########
## Nettoyage du dossier firmware
## > novembre 2024
##rev0.01

##UNIVERSALISATION
DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
if [ $DEBIAN_VER == "bullseye" ]; then firmwaredir=/boot/;
elif [ $DEBIAN_VER == "bookworm" ]; then firmwaredir=/boot/firmware/;
else
        echo "Erreur de script"
        exit 0;
fi

##DÉBUT DU SCRIPT
echo "Nettoyage du dossier $firmwaredir"
echo
cd $firmwaredir

sudo rm ./bcm2708*.dtb
sudo rm ./bcm2709*.dtb
sudo rm ./bcm2710*.dtb
sudo rm ./bcm2711-rpi-c*.dtb
sudo rm ./bcm2711-rpi-400.dtb
sudo rm ./bcm2712*.dtb

sudo rm ./fixup.dat
sudo rm ./fixup_*.dat

sudo rm ./start.elf
sudo rm ./start_*.elf

if [ -d /boot/firmware.bak ]; then sudo rm -R /boot/firmware.bak; fi
if [ -d /usr/lib/modules.bak ]; then sudo rm -R /usr/lib/modules.bak; fi

echo
exit 0
