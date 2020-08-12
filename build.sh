#!/usr/bin/env bash

# MMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMMMddNMMMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMMmhddMMMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMMmddddmMMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMMNddddddNMMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMMNddddddddNMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMNddhhddhhddMMMMMMMMMMMMMMM
# MMMMMMMMMMMMMMdddddddddddmMMMMMMMMMMMMMM
# MMMMMMMMMMMMMmddddddddddddmMMMMMMMMMMMMM
# MMMMMMMMMMMMmdhhdhhhhddddddmMMMMMMMMMMMM
# MMMMMMMMMMMmdddhdhdhdhhhhhddmMMMMMMMMMMM
# MMMMMMMMMMmdddddddyoohdddddddmMMMMMMMMMM
# MMMMMMMMMmddhhhhdh-..:ddhdddddmMMMMMMMMM
# MMMMMMMMmdddddddyo+::ooydddddddNMMMMMMMM
# MMMMMMMmddddhhdd+......+ddddddddNMMMMMMM
# MMMMMMmddddddddyo::::::oyddddddddmMMMMMM
# MMMMMmddddddddd//+oooo++/dddddddddmMMMMM
# MMMMmddddmmNNNMMMMMMMMMMMMMNNmmddddmMMMM
# MMMmdmmNMMMMMMMMMMMMMMMMMMMMMMMMNNmdmMMM
# MNmmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmNM
# NNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNN

# zenlinux build script

# Author: Lucas Barbosa (llbarbosas)


# Packages

DIR="$(cd "$(dirname $0)" && pwd)"
PKGS_DIR="$DIR/packages"
PKGS="$(ls $PKGS_DIR)"
LOCALREPO_DIR="$DIR/localrepo"
BUILD_SCRIPT="$DIR/releng/build.sh"

# Releng files backup

PACMANCONF="$DIR/releng/pacman.conf"
PACMANCONF_COPY="$(mktemp)"
cat $PACMANCONF > $PACMANCONF_COPY

PACKAGES="$DIR/releng/packages.x86_64"
PACKAGES_COPY="$(mktemp)"
cat $PACKAGES > $PACKAGES_COPY


function cleanup() {
	echo "[*] Cleaning all up"
	rm -rf $LOCALREPO_DIR

	mv -f $PACMANCONF_COPY $PACMANCONF
	mv -f $PACKAGES_COPY $PACKAGES

	exit
}


function build_packages() {
	cd $DIR

	echo "[*] Building packages"

	git submodule update --init

	for pkg in $PKGS; do
		echo "[*] Building $pkg"
		cd $PKGS_DIR/$pkg 
		makepkg -sC --noconfirm # > /dev/null 2>&1

	done
}

function mk_localrepo() {
	echo "[*] Creating localrepo"
	
	mkdir $LOCALREPO_DIR
	
	for pkg in $PKGS; do
		echo "[*] Moving $pkg to localrepo"
		mv $PKGS_DIR/$pkg/*.pkg.tar.zst ../../localrepo
	done

	pkgs_files="$(ls $DIR/localrepo/*.pkg.tar.zst)"
	
	echo "[*] Adding $pkgs_files to localrepo"

	repo-add $LOCALREPO_DIR/localrepo.db.tar.gz $pkgs_files > /dev/null 2>&1

	echo "[*] Adding localrepo to releng/pacman.conf"
	
	echo "#[localrepo]" >> $PACMANCONF
	echo "SigLevel = Optional TrustAll" >> $PACMANCONF
	echo "Server = file://$LOCALREPO_DIR"
}

function build_iso() {
	echo "[*] Using releng/build.sh to build the iso"

	sudo $BUILD_SCRIPT -N "zenlinux" -L "ZEN_202008" -P "Lucas Barbosa <http://llbarbosas.dev>" -A "zenlnux LiveCD"
}

trap cleanup SIGINT

build_packages
mk_localrepo
build_iso

# cleanup
