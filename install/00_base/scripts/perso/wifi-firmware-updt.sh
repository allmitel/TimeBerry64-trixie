#!/bin/bash
##rev0.02 #27/09/2024 test de versions du firmware
if [[ "$(id -u)" -ne 0 ]]; then
	echo "Ce script doit être lancé à partir de l'utilisateur root. Try 'sudo $0'"
	exit 1
fi


echo "Mise à jour du firmware Wifi Mediatek mt7921au"
echo
cd /lib/firmware/mediatek

FILE1_LOCAL=$(head -c 15 /lib/firmware/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin)
FILE1_DISTANT=$(curl -s -r 0-15 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin | head -c 15)
if [ "$FILE1_LOCAL" != "$FILE1_DISTANT" ]; then
        echo "Nouvelle version du fichier WIFI_MT7961_patch_mcu_1_2_hdr.bin trouvée!"
        sudo mv WIFI_MT7961_patch_mcu_1_2_hdr.bin WIFI_MT7961_patch_mcu_1_2_hdr.bin.bak
        curl -s -LO https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_MT7961_patch_mcu_1_2_hdr.bin
		cp -a ./WIFI_MT7961_patch_mcu_1_2_hdr.bin /boot/firmware/install/00_base/wifi/
        echo "> nouvelle version téléchargée";
else
        echo "Pas de nouvelle version du driver";
fi


FILE2_LOCAL=$(head -c 50 /lib/firmware/mediatek/WIFI_RAM_CODE_MT7961_1.bin | tr -d '\0')
FILE2_DISTANT=$(curl -s -r 0-50 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_RAM_CODE_MT7961_1.bin | head -c 50 | tr -d '\0')
if [ "$FILE2_LOCAL" != "$FILE2_DISTANT" ]; then
        echo "Nouvelle version du fichier WIFI_RAM_CODE_MT7961_1.bin trouvée!"
        sudo mv WIFI_RAM_CODE_MT7961_1.bin WIFI_RAM_CODE_MT7961_1.bin.bak
        curl -s -LO https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/WIFI_RAM_CODE_MT7961_1.bin
        echo "> nouvelle version téléchargée";
else
        echo "Pas de nouvelle version du driver";
fi
sleep 0.5
echo "All done!"
exit 0
