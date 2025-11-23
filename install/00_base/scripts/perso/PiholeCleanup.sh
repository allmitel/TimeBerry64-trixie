#!/bin/bash
##rev0.01
echo '#######################'
echo '## Pihole Cleanup V1 ##'
echo '#######################'
echo
sleep 1
echo "Extinction du service DNS et de PiHole"
sudo service pihole-FTL stop
echo "done"
sleep 5
echo
echo "Nettoyage de la base de donnée des machines connectées"
sudo pihole arpflush
#sudo -u pihole sqlite3 /etc/pihole/pihole-FTL.db "DELETE FROM network"
echo "done"
echo
echo "Remise en route du système et flush des logs"
sudo service pihole-FTL start
sleep 5
pihole -f
echo "done"
echo
