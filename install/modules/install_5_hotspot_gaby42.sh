#!/usr/bin/env bash

######################################
## TimeBerry Fast Install           ##
## sous-script installation Hotspot ##
######################################

# v.0 - 8 février 2024 s
########################
## note : modification le 19 avril pour rendre plus compréhensible wificard --> wifi4Gcard
# v.0a - 20 juin 2025 - check inversion cartes wifi pour installation 4G/5G sur externe

########################################################
## CONFIGURATION AUTOMATIQUE DU HOTSPOT AVEC 2 CARTES ##
########################################################

#Configuration de base
#Début du script
install_hotspot (){
echo "> hotspot in"

apt-get install hostapd dnsmasq -qq > /dev/null

if [ "$DEBIAN_VER" == "bookworm" ] || [ "$DEBIAN_VER" == "trixie" ]; then
	apt-get install dhcpcd -qq > /dev/null
fi

if [ ! -d $homedir/.config ]; then 
	mkdir $homedir/.config && chown pi:pi $homedir/.config;
fi

if [ -e /home/pi/.config/.wifi4G ]; then
	wifi4Gcard="$(cat $homedir/.config/.wifi4G)";
else
	wifi4Gcard="wlan1"
	echo "$wifi4Gcard" > $homedir/.config/.wifi4G;
fi

## variable pour hotspot (l'inverse de ce qui a été choisi pour la connection 4G)
if [ $wifi4Gcard == "wlan0" ]; then
	hotspotcard="wlan1";
else
	hotspotcard="wlan0";
fi

## WPA SUPPLICANT
## Adaptation bookworm, wpa_supplicant n'est plus sûr
#mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-$wifi4Gcard.conf
cp $basedir/wpa_supplicant_gaby42.conf /etc/wpa_supplicant/wpa_supplicant-$wifi4Gcard.conf
systemctl disable wpa_supplicant

if [ "$DEBIAN_VER" == "bookworm" ] || [ "$DEBIAN_VER" == "trixie" ]; then
	systemctl disable NetworkManager.service
fi

systemctl enable wpa_supplicant@$wifi4Gcard

## DHCPCD.conf
cp $basedir/Hotspot/dhcpcd.conf /etc/dhcpcd.conf && chown root:root /etc/dhcpcd.conf && chmod 644 /etc/dhcpcd.conf
sed -i "s/wificard_stub/$wifi4Gcard/g" /etc/dhcpcd.conf
sed -i "s/hotspotcard_stub/$hotspotcard/g" /etc/dhcpcd.conf

if [ "$DEBIAN_VER" == "bookworm" ]; then
#	systemctl enable systemd.networkd.service
	systemctl enable dhcpcd.service

fi



## Activer le transfert de paquets
#sed -i "s/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
cp $basedir/Hotspot/sysctl-trixie.conf /etc/sysctl.d/ && chmod 644 /etc/sysctl.d/sysctl-trixie.conf



## Hostapd
cp $basedir/Hotspot/hostapd/*.conf /etc/hostapd/ && chown root:root /etc/hostapd/*.conf && chmod 644 /etc/hostapd/*.conf

## Scan des canaux
sudo apt install nodejs -y
sudo cp $basedir/Hotspot/*.js /etc/hostapd/ && chmod 744 /etc/hostapd/*.js

##config réseauN & réseauAC
cp /etc/hostapd/N.conf /etc/hostapd/$hotspotcard.N
cp /etc/hostapd/AC.conf /etc/hostapd/$hotspotcard.AC
sed -i "s/hotspotcard_stub/$hotspotcard/" /etc/hostapd/$hotspotcard.N
sed -i "s/hotspotcard_stub/$hotspotcard/" /etc/hostapd/$hotspotcard.AC

if [ $hotspotcard == "wlan0" ]; then

		##MODIF ADAPTATION POUR BOOKWORM -- neutralisé le 20 juin 2025
		## apparemment fonctionnement instable? donc remis le 10 juillet 2025
		if [ "$DEBIAN_VER" == "bookworm" ] || [ "$DEBIAN_VER" == "trixie" ]; then
		        cardconfig_n="[MAX-AMSDU-3839][HT40][SHORT-GI-20][DSSS_CCK-40]";
		else
				cardconfig_n="[MAX-AMSDU-3839][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]"#;
		fi
        cardconfig_ac="[MAX-AMSDU-3839][SHORT-GI-80][SU-BEAMFORMEE]"
        wifichannelN="4"
        wifichannelAC="100"
        wifichannelAC_secondary="106";
        
else # le hotspot est dans ce cas sur la carte wlan1

		if [ "$DEBIAN_VER" == "bookworm" ] || [ "$DEBIAN_VER" == "trixie" ]; then
#		        cardconfig_n="[MAX-AMSDU-7935][HT40][SHORT-GI-40][LDPC]";
				## essai selon site : https://github.com/morrownr/USB-WiFi/blob/main/home/AP_Mode/hostapd-WiFi4.conf
				cardconfig_n="[LDPC][HT40+][HT40-][GF][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][MAX-AMSDU-7935]";
		else
				cardconfig_n="[MAX-AMSDU-7935][HT40+][SHORT-GI-20][SHORT-GI-40][LDPC]";
		fi
        cardconfig_ac="[MAX-AMSDU-7935][MAX-MPDU-65535][SHORT-GI-80][RXLDPC][SU-BEAMFORMEE][MU-BEAMFORMEE][MAX-A-MPDU-LEN-EXP3]"
        wifichannelN="4"
        wifichannelAC="149"
        wifichannelAC_secondary="155";
fi
sed -i "s/^ht_capab=$/ht_capab=$cardconfig_n/" /etc/hostapd/$hotspotcard.N
sed -i "s/wifichannelN_stub/$wifichannelN/g" /etc/hostapd/$hotspotcard.N

sed -i "s/^ht_capab=$/ht_capab=$cardconfig_n/" /etc/hostapd/$hotspotcard.AC
sed -i "s/^vht_capab=$/vht_capab=$cardconfig_ac/" /etc/hostapd/$hotspotcard.AC
sed -i "s/wifichannelAC_stub/$wifichannelAC/g" /etc/hostapd/$hotspotcard.AC
sed -i "s/wifichannelAC_secondary_stub/$wifichannelAC_secondary/g" /etc/hostapd/$hotspotcard.AC
echo "Copie du fichier final"

cp /etc/hostapd/$hotspotcard.N /etc/hostapd/$hotspotcard.conf
systemctl disable hostapd
systemctl enable hostapd@$hotspotcard

## Dnsmasq
cp $basedir/Hotspot/dnsmasq.conf /etc/dnsmasq.conf && chown root:root /etc/dnsmasq.conf && chmod 644 /etc/dnsmasq.conf
sed -i "s/hotspotcard_stub/$hotspotcard/" /etc/dnsmasq.conf

## Nftables
mkdir /etc/nftables
cp $basedir/Hotspot/ruleset.nft /etc/nftables/
cp $basedir/Hotspot/note.md /etc/nftables/
sed -i "s/wificard_stub/$wifi4Gcard/g" /etc/nftables/ruleset.nft
sed -i "s/hotspotcard_stub/$hotspotcard/g" /etc/nftables/ruleset.nft
sed -i "s/wificard_stub/$wifi4Gcard/g" /etc/nftables/note.md
sed -i "s/hotspotcard_stub/$hotspotcard/g" /etc/nftables/note.md
cat << EOF >> /etc/nftables.conf

include "/etc/nftables/ruleset.nft"
EOF
systemctl enable nftables

echo "> hotspot done"
}