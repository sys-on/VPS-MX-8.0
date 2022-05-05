#!/bin/bash

### COLORES Y BARRA 
msg () {
BRAN='\033[1;37m' && VERMELHO='\e[31m' && VERDE='\e[32m' && AMARELO='\e[33m'
AZUL='\e[34m' && MAGENTA='\e[35m' && MAG='\033[1;36m' &&NEGRITO='\e[1m' && SEMCOR='\e[0m'
 case $1 in
  -ne)cor="${VERMELHO}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}";;
  -ama)cor="${AMARELO}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verm)cor="${AMARELO}${NEGRITO}[!] ${VERMELHO}" && echo -e "${cor}${2}${SEMCOR}";;
  -azu)cor="${MAG}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -verd)cor="${VERDE}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}";;
  -bra)cor="${VERMELHO}" && echo -ne "${cor}${2}${SEMCOR}";;
  "-bar2"|"-bar")cor="${VERMELHO}======================================================" && echo -e "${SEMCOR}${cor}${SEMCOR}";;
 esac
}
rm -rf instalscript.sh
## Script name
SCRIPT_NAME=vpsmxup

## Title and graphics
echo "         VPS-MX - $(date)"
msg -bar2

## Enviroment variables
TIME_START="$(date +%s)"
DOWEEK="$(date +'%u')"
HOSTNAME="$(hostname)"

## Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT_FULLPATH=$(readlink -f "$0")
SCRIPT_HASH=`md5sum ${SCRIPT_FULLPATH} | awk '{ print $1 }'`

## Absolute path this script is in, thus /home/user/bin
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

## Config files
CONFIGFILE_NAME=$SCRIPT_NAME.conf
CONFIGFILE_FULLPATH_DEFAULT=/usr/local/vpsmxup/vpsmxup.default.conf
CONFIGFILE_FULLPATH_ETC=/etc/vpsmxup/$CONFIGFILE_NAME
CONFIGFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_NAME

## Title printing function
function printTitle {
    echo ""
    echo -e "\033[92m$1\033[31m"
    printf '%0.s=' $(seq 1 ${#1})
    echo ""
}

## root check
if ! [ $(id -u) = 0 ]; then

		echo ""
		echo "vvvvvvvvvvvvvvvvvvvv"
		echo "    Erro Fatal!!"
		echo "^^^^^^^^^^^^^^^^^^^^"
		echo "Este script deve ser executado como root!"

		printTitle "How to fix it?"
		echo "Execute o script assim:"
		echo "sudo $SCRIPT_NAME"

		printTitle "The End"
		echo $(date)
		msg -bar2
		exit
fi

## Profile requested
if [ ! -z "$1" ]; then

	CONFIGFILE_PROFILE_NAME=${SCRIPT_NAME}.profile.${1}.conf
	CONFIGFILE_PROFILE_FULLPATH_ETC=/etc/vpsmxup/$CONFIGFILE_PROFILE_NAME
	CONFIGFILE_PROFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_PROFILE_NAME

	if [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_ETC" ] && [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_DIR" ]; then

		echo ""
		echo "vvvvvvvvvvvvvvvvvvvv"
		echo "erro catastrófico!!"
		echo "^^^^^^^^^^^^^^^^^^^^"
		echo "Profile config file(s) not found:"
		echo "[X] $CONFIGFILE_PROFILE_FULLPATH_ETC"
		echo "[X] $CONFIGFILE_PROFILE_FULLPATH_DIR"

		printTitle "How to fix it?"
		echo "Create a config file for this profile:"
		echo "sudo cp $CONFIGFILE_FULLPATH_DEFAULT $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo nano $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo chmod ugo=rw /etc/vpsmxup/*.conf"

		printTitle "The End"
		echo $(date)
		msg -bar2
		exit
	fi
fi


for CONFIGFILE_FULLPATH in "$CONFIGFILE_FULLPATH_DEFAULT" "$CONFIGFILE_MYSQL_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_DIR" "$CONFIGFILE_PROFILE_FULLPATH_ETC" "$CONFIGFILE_PROFILE_FULLPATH_DIR"
do
	if [ -f "$CONFIGFILE_FULLPATH" ]; then
		source "$CONFIGFILE_FULLPATH"
	fi
done
	
printTitle "atualização automática"
INSTALL_DIR_PARENT="/usr/local/vpsmxup/"


SCRIPT_HASH_AFTER_UPDATE=`md5sum ${SCRIPT_FULLPATH} | awk '{ print $1 }'`
if [ "$SCRIPT_HASH" != "$SCRIPT_HASH_AFTER_UPDATE" ]; then
		echo ""
		echo "vvvvvvvvvvvvvvvvvvvvvv"
		echo "Self-update installed!"
		echo "^^^^^^^^^^^^^^^^^^^^^^"
		echo "zzupdate itself has been updated!"
		echo "Please run zzupdate again to update your system."

		printTitle "The End"
		echo $(date)
		msg -bar2
		exit
fi


if [ "$SWITCH_PROMPT_TO_NORMAL" = "1" ]; then

	printTitle "Switching to the 'normal' release channel (if 'never' or 'lts')"
	sed -i -E 's/Prompt=(never|lts)/Prompt=normal/g' "/etc/update-manager/release-upgrades"
	
else

	printTitle "A mudança de canal está desativada"
	
fi


printTitle "Limpeza de cache local"
apt-get clean

printTitle "Atualizar informações de pacotes disponíveis"
apt-get update

printTitle "PACOTES DE ATUALIZAÇÃO"
apt-get dist-upgrade -y

if [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "1" ]; then

	printTitle "Atualize silenciosamente para uma nova versão, se houver"
	do-release-upgrade -f DistUpgradeViewNonInteractive
	
elif [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "0" ]; then

	printTitle "Atualizar interativamente para uma nova versão, se houver"
	do-release-upgrade
	
else

	printTitle "Nova versão ignorada (desativada nas configurações)"
	
fi

if [ "$COMPOSER_UPGRADE" = "1" ]; then

	printTitle "composer de atualização automática"
	
	if ! [ -x "$(command -v composer)" ]; then
		echo "O composer não está instalado"
	else
		composer self-update
	fi
fi

if [ "$SYMFONY_UPGRADE" = "1" ]; then

	printTitle "Symfony com atualização automática"
	
	if ! [ -x "$(command -v symfony)" ]; then
		echo "Symfony não está instalado"
	else
		symfony self:update --yes
	fi
fi



printTitle "Limpeza de pacotes (remoção automática de pacotes não utilizados)"
apt-get autoremove -y

printTitle "Versão atual"
lsb_release -d

printTitle "Tempo que leva para atualizar"
echo "$((($(date +%s)-$TIME_START)/60)) min."
clear
msg -bar2
echo -e "\033[93m           -- ATUALIZAÇÃO QUASE COMPLETA -- "
echo -e "\033[97m  SUA VPS IRÁ REINICIAR PARA TERMINAR AS ATUALIZAÇÕES"
msg -bar2
echo -e "\033[93m               APÓS A REINICIALIZAÇÃO" 
echo -e "\033[93m                 DIGITE A PALAVRA\033[97m"
echo ""
echo -e "                  \033[1;41m sudo VPS-MX \033[0m"
msg -bar2

REBOOT=1
REBOOT_TIMEOUT=20

if [ "$REBOOT" = "1" ]; then
	printTitle "        SUA VPS REINICIARÁ EM 20 SEGUNDOS           "
	
	while [ $REBOOT_TIMEOUT -gt 0 ]; do
	   echo -ne "                         -$REBOOT_TIMEOUT-\033[0K\r"
	   sleep 1
	   : $((REBOOT_TIMEOUT--))
	done
	reboot
fi

printTitle "FIM"
echo $(date)
msg -bar2
