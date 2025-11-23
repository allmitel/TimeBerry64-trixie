#!/bin/sh

##################################
## Extinction/rallumage du wifi ##
## > avril 2024                 ##
##################################
WIFI_CARD=$(cat /home/pi/.config/.wifi4G)
echo "-+-+- Extinction du wifi -+-+-"
echo "à $(date)"
#/usr/sbin/rfkill block wlan
sudo service wpa_supplicant@$WIFI_CARD stop
echo "> extinction faite"
sleep 5
sudo iwconfig
#/usr/sbin/rfkill
exit 0
