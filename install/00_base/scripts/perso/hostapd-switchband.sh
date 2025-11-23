#!/bin/bash
##rev0.02 #7 sept 2024
##rev0.03 #10 juillet 2025 - nettoyage des paramètres de conf selon module install_hotspot_gaby42.sh

echo "TimeBerry64 : Hotspot hostapd@ et accès internet Gaby8"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "> Inversion de la bande wifi pour le Hotspot Timeberry"

DEBIAN_VER=$(cat /etc/os-release | grep VERSION_CODENAME | awk '{sub(/VERSION_CODENAME=/,""); print}')

# 1# déterminer la carte utilisée pour le Hotspot
config4G=$(cat /home/pi/.config/.wifi4G)
if [ "$config4G" == "wlan0" ];then
        hotspotcard="wlan1";
else
        hotspotcard="wlan0";
fi

# 2# déterminer la bande actuellement utilisée + variable nouvelle bande
if [ -e /etc/hostapd/"$hotspotcard".conf ]; then
	CONFFILE_BAND=$(cat /etc/hostapd/"$hotspotcard".conf | grep hw_mode= | awk '{sub(/hw_mode=/,""); print}');
#	if [ -e /etc/hostapd/"$config4G".conf ]; then rm /etc/hostapd/"$config4G".conf; fi
else
	CONFFILE_BAND="g";
fi


if [ "$CONFFILE_BAND" == "g" ];then
	OLD_HOTSPOTBAND="N"
	NEW_HOTSPOTBAND="AC";
elif [ "$CONFFILE_BAND" == "a" ]; then
	OLD_HOTSPOTBAND="AC"
	NEW_HOTSPOTBAND="N";
else
	echo "Erreur dans la configuration, il est plus sage de s'arrêter là."
	exit 0;
fi

echo "Le Hotsport Timeberry utilise actuellement la bande $OLD_HOTSPOTBAND sur la carte $hotspotcard"
echo
echo
sleep 1
echo "> Bascule vers la bande $NEW_HOTSPOTBAND"
echo
echo
sleep 1

# 3# vérification de l'existence du fichier de config préconçu
if [ ! -e /etc/hostapd/$hotspotcard.$NEW_HOTSPOTBAND ]; then
	echo "Le fichier de config pour la bande $NEW_HOTSPOTBAND n'exitait pas!"
	echo "> création du fichier"


#CREATION DU FICHIER
	cp /etc/hostapd/$NEW_HOTSPOTBAND.conf /etc/hostapd/$hotspotcard.$NEW_HOTSPOTBAND
	#modif du fichier de configuration pour prendre en compte les bonnes options de la carte choisie
#CHOIX CARTE DANS FICHIER
	sed -i "s/hotspotcard_stub/$hotspotcard/" /etc/hostapd/$hotspotcard.$NEW_HOTSPOTBAND
#PARAMÈTRAGE DES VARIABLES POUR FICHIER
	if [ "$hotspotcard" == "wlan0" ]; then
		if [ "$DEBIAN_VER" == "bookworm" ];then
			cardconfig_n="[MAX-AMSDU-3839][HT40][SHORT-GI-20][DSSS_CCK-40]";
		else
			cardconfig_n="[MAX-AMSDU-3839][HT40+][SHORT-GI-20][SHORT-GI-40][DSSS_CCK-40]";
		fi	
			cardconfig_ac="[MAX-AMSDU-3839][SHORT-GI-80][SU-BEAMFORMEE]"
        	wifichannelN="4"
	        wifichannelAC="100"
	        wifichannelAC_secondary="106";
	else #forcément wlan1 par définition de la variable plus haut
		if [ "$DEBIAN_VER" == "bookworm" ];then
			cardconfig_n="[LDPC][HT40+][HT40-][GF][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][MAX-AMSDU-7935]";
		else
			cardconfig_n="[MAX-AMSDU-7935][HT40+][SHORT-GI-20][SHORT-GI-40][LDPC]";
		fi
        	cardconfig_ac="[MAX-AMSDU-7935][MAX-MPDU-65535][SHORT-GI-80][RXLDPC][SU-BEAMFORMEE][MU-BEAMFORMEE][MAX-A-MPDU-LEN-EXP3]"
        	wifichannelN="4"
       		wifichannelAC="149"
        	wifichannelAC_secondary="155";
	fi
#ENREGISTREMENT DES PARAMÈTRES
	if [ "$NEW_HOTSPOTBAND" == "N" ]; then
		sed -i "s/^ht_capab=$/ht_capab=$cardconfig_n/" /etc/hostapd/$hotspotcard.N
		sed -i "s/wifichannelN_stub/$wifichannelN/g" /etc/hostapd/$hotspotcard.N;
	else #forcément AC par définition de la variable plus haut
		sed -i "s/^ht_capab=$/ht_capab=$cardconfig_n/" /etc/hostapd/$hotspotcard.AC
		sed -i "s/^vht_capab=$/vht_capab=$cardconfig_ac/" /etc/hostapd/$hotspotcard.AC
		sed -i "s/wifichannelAC_stub/$wifichannelAC/g" /etc/hostapd/$hotspotcard.AC
		sed -i "s/wifichannelAC_secondary_stub/$wifichannelAC_secondary/g" /etc/hostapd/$hotspotcard.AC;
	fi;
fi



# 4# déplacement du fichier de configuration au bon endroit (écrasement du fichier de conf en place)
cp /etc/hostapd/$hotspotcard.$NEW_HOTSPOTBAND /etc/hostapd/$hotspotcard.conf

# 5# relance du hotspot sur la nouvelle bande - à risque si on est connecté via ssh sur le Hotspot!
#service hostapd@$hotspotcard restart
# déterminer si mon ordi est connecté au Hotspot

CHECK_RUNNING=$(service hostapd@$hotspotcard status | grep running | awk '{sub(/\(/,"");sub(/\)/,"");print $3}')
if [ "$CHECK_RUNNING" == "running" ]; then
	CHECK_CONNECT=$(service hostapd@$hotspotcard status | grep e0:ac:cb:8f:50:5a\ IEEE | tail -1 | awk '{print $11}')
	ROTATED=$(service hostapd@$hotspotcard status | grep rotated | awk '{print $1}')
	if [ "$CHECK_CONNECT" == "associated" ]; then
		echo "L'ordi est actuellement connecté au Hotspot Timeberry-$OLD_HOTSPOTBAND"
		echo "On ne peut faire le changement de bande maintenant"
		echo "> se déconnecter et refaire le changement à ce moment-là";
	elif [ "$ROTATED" == "Warning:" ]; then
		echo "Le journal a récemment été nettoyé par la commande rmHist"
		echo "impossible de savoir le statut de la connection"
		echo "On ne peut faire le changement de bande maintenant"
		echo "> faire un check manuel";
	else
	#	echo "DO SWITCH COMMAND : autre réseau";
		service hostapd@$hotspotcard restart;
	fi;
else
#        echo "DO SWITCH COMMAND : hotspot éteint";
	service hostapd@$hotspotcard restart;
fi
exit 0
