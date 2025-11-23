#!/usr/bin/sh

#############################################
## Script de mise à jour du système        ##
## Lancement hebdomadaire par /etc/crontab ##
## > Version avec check des app compilées  ##
#############################################

############
## CHANGELOG
# 3 janvier 2022 : check > version pour vulkan branche 21.3
# 21 avril 2022 : check > version de vulkan (21.3.8 à date) + cloudflared
# 4 janvier 2023 : corrections pour que ça refonction (bash>sh)
# 3 avril 2023 : redéfinition du système de branche - utilisation de variable

############
## VARIABLES

count_upgrades=0
do_reboot=0

############
## FONCTIONS

#####################
## DEBUT DU SCRIPT ##
#####################
echo "-+-+- Mise à jour du système -+-+-"
echo


sudo apt-get update
# comptage des upgrades à faire + incrémentation de la variable reboot si jamais
count_upgrades=$(apt list --upgradable | wc -l)
count_upgrades=$((count_upgrades-2))
echo "nombre d'updates = $count_upgrades"
if [ "$count_upgrades" -gt 5 ]; then
	do_reboot=1;
fi
# mise à jour effective
echo "Ici on upgrade"
#sudo apt-get upgrade -y
echo "    -+-+-+-+-    "
echo


#Test pour savoir si on redémarre - commande de redémarrage
#
if [ $do_reboot = 1 ]; then
	echo "Redémarrage dans 10 secondes"
	sleep 10
	echo "Ici on reboot";
#	sudo reboot;
else
	echo "Pas de redémarrage"
	exit 0;
fi
