#!/bin/bash
##rev0.03 - 11 octobre 2024
echo "TimeBerry64 : Hotspot hostapd@ et accès internet Gaby8"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "> Inversion des cartes wifi pour l'accès internet et le Hotspot"
echo
##VERSION DE DEBIAN
DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')
export DEBIAN_VER

##VALEUR DU WIFI INSTALLÉ AU MOMENT DU LANCEMENT DU SCRIPT
if [ -e /home/pi/.config/.wifi4G ]; then
	OLD4G=$(cat /home/pi/.config/.wifi4G);
else
	echo "> erreur un fichier manquant!\nOn s'arrête là pour éviter de tout casser!"
	exit 1;
fi

## AFFICHAGE DE LA CONFIG D'ORIGINE
echo "La connexion internet est actuellement configurée pour utiliser la carte : $OLD4G"
#variables pour switch card
if [ "$OLD4G" == "wlan1" ]; then
	NEW4G="wlan0"
	OLDHotspot="wlan0"
	NEWHotspot="wlan1";
else
	NEW4G="wlan1"
	OLDHotspot="wlan1"
	NEWHotspot="wlan0";
fi
echo
echo "> la nouvelle configuration utilisera la carte $NEW4G pour l'accès internet"
echo "> la nouvelle configuration utilisera la carte $NEWHotspot pour déployer un Hotspot Timeberry"

##PROCESS ET BESOINS :
# changer le service wpa_supplicant
# modifier dhcpcd.conf pour :
#	vérifier que les bonnes cartes soient attribuées au bonnes plages d'IP
#	s'assurer que le service ne lance pas un wpa_supplicant sur la mauvaise carte automatiquement
# modifier dnsmasq.conf pour :
#	distribuer les adresses IP du Hotspot sur la bonne carte
# modifier hostapd.conf :
#	déployer le Hotspot sur la bonne carte (avec les bonnes options de config).
# modifier nftables.conf :
#	rerouter les paquets internet dans le bon sens Gaby8 > Hotspot

## CHANGEMENT EFFECTIF :
# #1 wpa_supplicant
echo "Changement de la carte pour le réseau wifi : wpa_supplicant"
sudo mv /etc/wpa_supplicant/wpa_supplicant-$OLD4G.conf /etc/wpa_supplicant/wpa_supplicant-$NEW4G.conf
sudo systemctl disable wpa_supplicant@$OLD4G
sudo systemctl enable wpa_supplicant@$NEW4G

# #2 dhcpcd
echo "Changement de dhcpcd.conf"
sudo sed -i "s/$OLD4G/temp1/g" /etc/dhcpcd.conf 			## valeur temporaire pour rotation
sudo sed -i "s/$OLDHotspot/$NEWHotspot/g" /etc/dhcpcd.conf	## rotation 1>2>t
sudo sed -i "s/temp1/$NEW4G/g" /etc/dhcpcd.conf			## rotation t>1

# #3 dnsmasq
echo "Changement de dnsmasq.conf"
sudo sed -i "s/$OLDHotspot/$NEWHotspot/" /etc/dnsmasq.conf

# #4 hostapd
echo "Changement de carte pour le Hotspot : Hostapd"
if [ ! /etc/hostapd/$NEWHotspot.N ]; then
	echo "> le fichier de config initiale n'existe pas : création"
	sudo cp /etc/hostapd/N.conf /etc/hostapd/$NEWHotspot.N
	sudo sed -i "s/hotspotcard_stub/$NEWHotspot/" /etc/hostapd/$NEWHotspot.N

	if [ $NEWHotspot == "wlan0" ]; then
		echo "> config pour carte interne"
		##MODIF ADAPTATION POUR BOOKWORM
		if [ "$DEBIAN_VER" == "bookworm" ];then
			echo "> en version bookworm"
		        cardconfig_n="[MAX-AMSDU-3839][HT40][SHORT-GI-20][DSSS_CCK-40]";
		else
			echo "> en version bullseye"
			cardconfig_n="[MAX-AMSDU-3839][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]";
		fi;
	else
		echo "> config pour carte externe"
	        cardconfig_n="[MAX-AMSDU-7935][HT40+][SHORT-GI-20][SHORT-GI-40][LDPC]";
	fi
	sed -i "s/^ht_capab=$/ht_capab=$cardconfig_n/" /etc/hostapd/$NEWHotspot.N;
fi
sudo cp /etc/hostapd/$NEWHotspot.N /etc/hostapd/$NEWHotspot.conf
sudo rm /etc/hostapd/$OLDHotspot.conf
sudo systemctl disable hostapd@$OLDHotspot
sudo systemctl enable hostapd@$NEWHotspot

# #5 nftables
echo "Changement des ruleset.nft / nftables"
sudo sed -i "s/$OLD4G/temp2/g" /etc/nftables/ruleset.nft		## valeur temporaire pour rotation
sudo sed -i "s/$OLDHotspot/$NEWHotspot/g" /etc/nftables/ruleset.nft
sudo sed -i "s/temp2/$NEW4G/g" /etc/nftables/ruleset.nft

echo $NEW4G > /home/pi/.config/.wifi4G

echo
echo "FINI : UN REDÉMARRAGE DE LA MACHINE EST NÉCESSAIRE POUR PRENDRE EN COMPTE LE CHANGEMENT DE CARTE"
echo
exit 0
