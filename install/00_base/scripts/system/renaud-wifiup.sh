#!/bin/sh

##################################
## Extinction/rallumage du wifi ##
## > avril 2024                 ##
##################################
WIFI_CARD=$(cat /home/pi/.config/.wifi4G)
if [ "$WIFI_CARD" = "wlan0" ]; then
        HOTSPOT_CARD="wlan1";
else
        HOTSPOT_CARD="wlan0";
fi
echo "-+-+- Remise en place du réseau sur la bande 2,4Ghz - wifi N -+-+-"
sudo cp /etc/hostapd/$HOTSPOT_CARD.N /etc/hostapd/$HOTSPOT_CARD.conf
sudo service hostapd@$HOTSPOT_CARD restart

echo
echo "-+-+- Rallumage du wifi -+-+-"
echo "à "$(date)
#/usr/sbin/rfkill unblock wlan
sudo service wpa_supplicant@$WIFI_CARD start
echo "> rallumage fait"
sleep 10
sudo iwconfig
#/usr/sbin/rfkill
exit 0
