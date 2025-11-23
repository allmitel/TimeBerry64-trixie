#!/bin/bash
##rev0.01
echo '###################'
echo '## rmHist Script ##'
echo '###################'
echo
sleep 1
##########################################
echo '> Nettoyage historique et divers'
echo
if [ -e ~/.bash_history ]; then
	rm ~/.bash_history
	echo 'Historique bash nettoyée'
	echo;
fi

if [ -e ~/renaudRasp-update.log ]; then
    sudo rm ~/renaudRasp-update.log
    echo;
fi

echo
sleep 1
##########################################
echo "> Nettoyage du système basique"
echo
sleep 1

sudo apt-get -y autoremove
sudo apt-get clean


echo
sleep 1
##########################################
echo "> Nettoyage des fichiers .DS_Store"
echo
sudo find / \( -name ".DS_Store" -or -name ".Trashes" -or -name "._*" -or -name ".TemporaryItems" \)
sudo find / \( -name ".DS_Store" -or -name ".Trashes" -or -name "._*" -or -name ".TemporaryItems" \) -delete

sudo find / -type f -name ".DS_Store" -exec rm -f {} \;

echo
sleep 1
##########################################
echo "> Nettoyage des journaux"
echo
sleep 1
sudo journalctl --flush --rotate --vacuum-time=1s

exit 0