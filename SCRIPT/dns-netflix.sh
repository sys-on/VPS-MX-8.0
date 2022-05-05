#!/bin/bash
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPinst} ]] && exit
dnsnetflix () {
echo "nameserver $dnsp" > /etc/resolv.conf
#echo "nameserver 8.8.8.8" >> /etc/resolv.conf
/etc/init.d/ssrmu stop &>/dev/null
/etc/init.d/ssrmu start &>/dev/null
/etc/init.d/shadowsocks-r stop &>/dev/null
/etc/init.d/shadowsocks-r start &>/dev/null
msg -bar2
echo -e "${cor[4]}  DNS ADICIONADO COM SUCESSO"
} 
clear
msg -bar2
echo -e "\033[1;93m     GERADOR DE DNS PESSOAL By @USA1_BOT "
msg -bar2
echo -e "\033[1;39m Esta função permitirá que você assista Netflix com seu VPS"
msg -bar2
echo -e "\033[1;91m ¡ Eles só serão úteis se você registrou seu IP no BOT !"
echo -e "\033[1;39m Em aplicativos como HTTP Injector, KPN Rev, APKCUSTOM, etc."
echo -e "\033[1;39m Eles devem ser adicionados no aplicativo para usar esses DNS."
echo -e "\033[1;39m Em APPS como SS,SSR,V2RAY você não precisa adicioná-los."
msg -bar2
echo -e "\033[1;93m Lembre-se de escolher entre 1 DNS, seja EUA, BR, MX, CL \n de acordo com o que oBOT."
echo ""
echo -e "\033[1;97m Digite seu DNS para usar: \033[0;91m"; read -p "   "  dnsp
echo ""
msg -bar2
read -p " Esta seguro de continuar?  [ s | n ]: " dnsnetflix   
[[ "$dnsnetflix" = "s" || "$dnsnetflix" = "S" ]] && dnsnetflix
msg -bar2