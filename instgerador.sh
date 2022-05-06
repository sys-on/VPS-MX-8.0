#!/bin/bash
BARRA="\033[1;36m-----------------------------------------------------\033[0m"
IVAR="/etc/http-instas"
SCPT_DIR="/etc/SCRIPT"
SCPinstal="$HOME/install"
rm $(pwd)/$0

install_ini () {
clear
echo -e "$BARRA"
echo -e "\033[92m        -- INSTALAR PACOTES NECESSÁRIOS -- "
echo -e "$BARRA"
#bc
[[ $(dpkg --get-selections|grep -w "bc"|head -1) ]] || apt-get install bc -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "bc"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "bc"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install bc................... $ESTATUS "
#screen
[[ $(dpkg --get-selections|grep -w "screen"|head -1) ]] || apt-get install screen -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "screen"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "screen"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install screen............... $ESTATUS "
#nano
[[ $(dpkg --get-selections|grep -w "nano"|head -1) ]] || apt-get install nano -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "nano"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "nano"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install nano................. $ESTATUS "
#curl
[[ $(dpkg --get-selections|grep -w "curl"|head -1) ]] || apt-get install curl -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "curl"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "curl"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install curl................. $ESTATUS "
#netcat
[[ $(dpkg --get-selections|grep -w "netcat"|head -1) ]] || apt-get install netcat -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "netcat"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "netcat"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install netcat............... $ESTATUS "
#netcat-traditional
[[ $(dpkg --get-selections|grep -w "netcat-traditional"|head -1) ]] || apt-get install netcat-traditional -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "netcat-traditional"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "netcat-traditional"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install netcat-traditional... $ESTATUS "
#net-tools
[[ $(dpkg --get-selections|grep -w "net-tools"|head -1) ]] || apt-get net-tools -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "net-tools"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "net-tools"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install net-tools............ $ESTATUS "
#cowsay
[[ $(dpkg --get-selections|grep -w "cowsay"|head -1) ]] || apt-get install cowsay -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "cowsay"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "cowsay"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install cowsay............... $ESTATUS "
#figlet
[[ $(dpkg --get-selections|grep -w "figlet"|head -1) ]] || apt-get install figlet -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "figlet"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "figlet"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install figlet............... $ESTATUS "
#lolcat
apt-get install lolcat -y &>/dev/null
sudo gem install lolcat &>/dev/null
[[ $(dpkg --get-selections|grep -w "lolcat"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "lolcat"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install lolcat............... $ESTATUS "
#apache2
[[ $(dpkg --get-selections|grep -w "apache2"|head -1) ]] || apt-get install apache2 -y &>/dev/null
[[ $(dpkg --get-selections|grep -w "apache2"|head -1) ]] || ESTATUS=`echo -e "\033[91mFALHA NA INSTALAÇÃO"` &>/dev/null
[[ $(dpkg --get-selections|grep -w "apache2"|head -1) ]] && ESTATUS=`echo -e "\033[92mINSTALADO"` &>/dev/null
echo -e "\033[97m  # apt-get install apache2.............. $ESTATUS "
sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
service apache2 restart > /dev/null 2>&1 &
echo -e "$BARRA"
echo -e "\033[92m A instalação dos pacotes necessários terminou"
echo -e "$BARRA"
echo -e "\033[97m Se a instalação do pacote falhar"
echo -ne "\033[97m Você pode tentar novamente [s/n]: "
read inst
[[ $inst = @(s|S|y|Y) ]] && install_ini
}

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

ofus () {
unset server
server=$(echo ${txt_ofuscatw}|cut -d':' -f1)
unset txtofus
number=$(expr length $1)
for((i=1; i<$number+1; i++)); do
txt[$i]=$(echo "$1" | cut -b $i)
case ${txt[$i]} in
".")txt[$i]="*";;
"*")txt[$i]=".";;
"1")txt[$i]="@";;
"@")txt[$i]="1";;
"2")txt[$i]="?";;
"?")txt[$i]="2";;
"4")txt[$i]="%";;
"%")txt[$i]="4";;
"-")txt[$i]="K";;
"K")txt[$i]="-";;
esac
txtofus+="${txt[$i]}"
done
echo "$txtofus" | rev
}

verificar_arq () {
[[ ! -d ${IVAR} ]] && touch ${IVAR}
[[ ! -d ${SCPT_DIR} ]] && mkdir ${SCPT_DIR}
unset ARQ
case $1 in
"gerar.sh")ARQ="/usr/bin/";;
"http-server.py")ARQ="/bin/";;
*)ARQ="${SCPT_DIR}/";;
esac
mv -f ${SCPinstal}/$1 ${ARQ}/$1
chmod +x ${ARQ}/$1
}

meu_ip () {
MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MIP2=$(wget -qO- ipv4.icanhazip.com)
[[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
echo "$IP" > /usr/bin/vendor_code
}
function_verify () {
  permited=$(curl -sSL "https://raw.githubusercontent.com/sys-on/Control/main/Control-IP")
  [[ $(echo $permited|grep "${IP}") = "" ]] && {
  echo -e "\n\n\n\033[1;31m====================================================="
  echo -e "\033[1;31m       ¡O IP $(wget -qO- ipv4.icanhazip.com) NÃO É AUTORIZADO!"
  echo -e "\033[1;31m                CONTATO @Sys-on"
  echo -e "\033[1;31m=====================================================\n\n\n"
  [[ -d /etc/SCRIPT ]] && rm -rf /etc/SCRIPT
  exit 1
  } || {
  ### INTALAR VERCION DE SCRIPT
  v1=$(curl -sSL "https://raw.githubusercontent.com/sys-on/Generador_Gen_VPS-MX/main/Vercion")
  echo "$v1" > /etc/versin_script
  }
}

error_fun () {
msg -bar2 && msg -verm "ERRO de link VPS<-->GERADOR" && msg -bar2
[[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}
exit 1
}

invalid_key () {
msg -bar2 && msg -verm "#¡Chave inválida#! " && msg -bar2
[[ -e $HOME/lista-arq ]] && rm $HOME/lista-arq
exit 1
}

install_ini
meu_ip

clear
msg -bar2
figlet " -KEYGEN-" | lolcat
while [[ ! $Key ]]; do
msg -bar2 && msg -ne "# DIGITE A CHAVE #: " && read Key
tput cuu1 && tput dl1
done
msg -ne "# Verificando Chave # : "
cd $HOME
wget -O $HOME/lista-arq $(ofus "$Key")/$IP > /dev/null 2>&1 && echo -e "\033[1;32m Chave Completa" || {
   echo -e "\033[1;91m Chave Incompleta"
   invalid_key
   exit
   }
IP=$(ofus "$Key" | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}') && echo "$IP" > /usr/bin/vendor_code
sleep 1s
function_verify
updatedb
if [[ -e $HOME/lista-arq ]] && [[ ! $(cat $HOME/lista-arq|grep "CHAVE INVALIDA!") ]]; then
   msg -bar2
   msg -e "\033[1;33mBaixando arquivos... \033[1;31m[GEN_VPS-MX #MOD by @Sys-on]"
   REQUEST=$(ofus "$Key"|cut -d'/' -f2)
   [[ ! -d ${SCPinstal} ]] && mkdir ${SCPinstal}
   for arqx in $(cat $HOME/lista-arq); do
   echo -ne "\033[1;33mBaixando: \033[1;31m[$arqx] "
   wget --no-check-certificate -O ${SCPinstal}/${arqx} ${IP}:81/${REQUEST}/${arqx} > /dev/null 2>&1 && {
    echo -e "\033[1;31m- \033[1;32mRecibido!"
    verificar_arq "${arqx}"
   } || {
    echo -e "\033[1;31m- \033[1;31mFalha (não recibido!)"
    error_fun
   }
   done
   sleep 1s
   [[ ! -e /usr/bin/trans ]] && wget -O /usr/bin/trans https://raw.githubusercontent.com/sys-on/FERRAMENTA/main/trans &> /dev/null
   [[ -e /bin/http-server.py ]] && mv -f /bin/http-server.py /bin/http-server.sh && chmod +x /bin/http-server.sh
   IVAR2="/etc/key-gerador"
   echo "" > $IVAR
   [[ -e ${SCPT_DIR}/autorizar ]] && {
    cp /bin/http-server.sh /etc/SCRIPT
    mv /etc/SCRIPT/http-server.sh /etc/SCRIPT/http-server.py
    cp /usr/bin/gerar.sh /etc/SCRIPT
    rm ${SCPT_DIR}/autorizar
   }
   cd /etc/SCRIPT
   rm -rf FERRAMENTA KEY KEY! INVALIDA!
   rm $HOME/lista-arq
   [[ -d ${SCPinstal} ]] && rm -rf ${SCPinstal}  
   sed -i -e 's/\r$//' /usr/bin/gerar.sh
   echo "/usr/bin/gerar.sh" > /usr/bin/gerar && chmod +x /usr/bin/gerar
   echo -e "$BARRA"
   echo -e "\033[1;33m Perfeito, use o comando\n       \033[1;31mgerar.sh o gerar\n \033[1;33mpara administrar suas Chaves"
   echo -e "$BARRA"
   echo -ne "\033[0m"
   sed -i -e 's/\r$//' /usr/bin/gerar.sh
 else
    invalid_key
fi
rm -rf instgerador.sh
