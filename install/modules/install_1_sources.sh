#!/usr/bin/env bash

#############################################
## TimeBerry Fast Install                  ##
## sous-script installation Repo & sources ##
#############################################

# v.1 - 8 février 2024 
######################
# CHECK TRIXIE - NOUVELLE ARCHITECTURE

##############################
## REPO SOURCES AUTOMATIQUE ##
##############################

#Configuration de base

#Début du script
install_repo_sources() {
echo
echo "script > sources in"
echo

local varsources	
varsources=$(grep deb-src /etc/apt/sources.list.d/raspi.sources)
if [ "$varsources" != "Types: deb deb-src" ]; then
	apt clean
	echo "## Accès aux repos 'source' ##"
	echo
	sed -i 's/^Types: deb/Types: deb deb-src/g' /etc/apt/sources.list.d/debian.sources
	sed -i 's/^Types: deb/Types: deb deb-src/g' /etc/apt/sources.list.d/raspi.sources
	if [ -e /etc/apt/sources.list.d/vscode.list ]; then rm /etc/apt/sources.list.d/vscode.list; fi
	echo ">fait";
else
	echo "Les repos sources sont déjà installés";
fi
apt update > /dev/null
echo "> sources done"
}

echo
echo "script > sources out"
echo