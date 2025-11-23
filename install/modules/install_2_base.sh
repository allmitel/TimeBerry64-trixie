#!/usr/bin/env bash

#######################################
## TimeBerry Fast Install            ##
## sous-script installation de bases ##
#######################################

# v.1 - 8 février 2024
# updt-16mai2024 - BOOKWORM
# updt-16novembre2025 - CHECK TRIXIE
###########################

#Configuration de base

#Début du script
install_base() {
echo
echo "script > base in"
echo
apt-get upgrade -qq > /dev/null
apt-get autoremove -qq > /dev/null

# apt-get install locate shellcheck tree build-essential git autoconf automake libtool xmltoman libdaemon-dev libpopt-dev libconfig-dev libasound2-dev libavahi-client-dev libssl-dev libsoxr-dev libflac-dev gldriver-test libgl1-mesa-dri libegl1-mesa libegl-mesa0 libgles2-mesa libudev-dev libxkbcommon-dev libusb-1.0-0-dev libx11-xcb-dev libgbm-dev libdrm-dev libxxf86vm-dev libgles2-mesa-dev libegl1-mesa-dev libgl*-mesa-dev -y
apt-get install locate shellcheck tree pbzip2
echo "> base done"

case "$1" in
	install_vulkan_deps)
		echo "## Installation des dépendances de compilation pour Vulkan ##"
		apt-get build-dep mesa -qq > /dev/null
		apt-get install python3-setuptools libxcb-shm0-dev -qq > /dev/null
		echo "> vulkan_deps done"
		if [ ! -d $homedir/.config ]; then 
				mkdir $homedir/.config && chown pi:pi $homedir/.config;
		fi
		touch $homedir/.config/.mesaPrepDone
	;;
esac
}
echo
echo "script > base out"
echo