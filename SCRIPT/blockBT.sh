#!/bin/bash
#19/12/19
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
SCPfrm="/etc/ger-frm" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="/etc/ger-inst" && [[ ! -d ${SCPinst} ]] && exit

sh_ver="1.0.11"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Informacion]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"

smtp_port="25,26,465,587"
pop3_port="109,110,995"
imap_port="143,218,220,993"
other_port="24,50,57,105,106,158,209,1109,24554,60177,60179"
bt_key_word="torrent
.torrent
peer_id=
announce
info_hash
get_peers
find_node
BitTorrent
announce_peer
BitTorrent protocol
announce.php?passkey=
magnet:
xunlei
sandai
Thunder
XLLiveUD"

check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_BT(){
	Cat_KEY_WORDS
	BT_KEY_WORDS=$(echo -e "$Ban_KEY_WORDS_list"|grep "torrent")
}
check_SPAM(){
	Cat_PORT
	SPAM_PORT=$(echo -e "$Ban_PORT_list"|grep "${smtp_port}")
}
Cat_PORT(){
	Ban_PORT_list=$(iptables -t filter -L OUTPUT -nvx --line-numbers|grep "REJECT"|awk '{print $13}')
}
Cat_KEY_WORDS(){
	Ban_KEY_WORDS_list=""
	Ban_KEY_WORDS_v6_list=""
	if [[ ! -z ${v6iptables} ]]; then
		Ban_KEY_WORDS_v6_text=$(${v6iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
		Ban_KEY_WORDS_v6_list=$(echo -e "${Ban_KEY_WORDS_v6_text}"|sed -r 's/.*\"(.+)\".*/\1/')
	fi
	Ban_KEY_WORDS_text=$(${v4iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
	Ban_KEY_WORDS_list=$(echo -e "${Ban_KEY_WORDS_text}"|sed -r 's/.*\"(.+)\".*/\1/')
}
View_PORT(){
	Cat_PORT
	echo -e "========${Red_background_prefix} Porta atualmente bloqueada ${Font_color_suffix}========="
	echo -e "$Ban_PORT_list" && echo && echo -e "==============================================="
}
View_KEY_WORDS(){
	Cat_KEY_WORDS
	echo -e "============${Red_background_prefix} Atualmente banido ${Font_color_suffix}============"
	echo -e "$Ban_KEY_WORDS_list" && echo -e "==============================================="
}
View_ALL(){
	echo
	View_PORT
	View_KEY_WORDS
	echo
	msg -bar2
}
Save_iptables_v4_v6(){
	if [[ ${release} == "centos" ]]; then
		if [[ ! -z "$v6iptables" ]]; then
			service ip6tables save
			chkconfig --level 2345 ip6tables on
		fi
		service iptables save
		chkconfig --level 2345 iptables on
	else
		if [[ ! -z "$v6iptables" ]]; then
			ip6tables-save > /etc/ip6tables.up.rules
			echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules" > /etc/network/if-pre-up.d/iptables
		else
			echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules" > /etc/network/if-pre-up.d/iptables
		fi
		iptables-save > /etc/iptables.up.rules
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Set_key_word() { $1 -t mangle -$3 OUTPUT -m string --string "$2" --algo bm --to 65535 -j DROP; }
Set_tcp_port() {
	[[ "$1" = "$v4iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
	[[ "$1" = "$v6iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with tcp-reset
}
Set_udp_port() { $1 -t filter -$3 OUTPUT -p udp -m multiport --dports "$2" -j DROP; }
Set_SPAM_Code_v4(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
		do
		Set_tcp_port $v4iptables "$i" $s
		Set_udp_port $v4iptables "$i" $s
	done
}
Set_SPAM_Code_v4_v6(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
	do
		for j in $v4iptables $v6iptables
		do
			Set_tcp_port $j "$i" $s
			Set_udp_port $j "$i" $s
		done
	done
}
Set_PORT(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
		Set_tcp_port $v6iptables $PORT $s
		Set_udp_port $v6iptables $PORT $s
	elif [[ -n "$v4iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
	fi
	Save_iptables_v4_v6
}
Set_KEY_WORDS(){
	key_word_num=$(echo -e "${key_word}"|wc -l)
	for((integer = 1; integer <= ${key_word_num}; integer++))
		do
			i=$(echo -e "${key_word}"|sed -n "${integer}p")
			Set_key_word $v4iptables "$i" $s
			[[ ! -z "$v6iptables" ]] && Set_key_word $v6iptables "$i" $s
	done
	Save_iptables_v4_v6
}
Set_BT(){
	key_word=${bt_key_word}
	Set_KEY_WORDS
	Save_iptables_v4_v6
}
Set_SPAM(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_SPAM_Code_v4_v6
	elif [[ -n "$v4iptables" ]]; then
		Set_SPAM_Code_v4
	fi
	Save_iptables_v4_v6
}
Set_ALL(){
	Set_BT
	Set_SPAM
}
Ban_BT(){
	check_BT
	[[ ! -z ${BT_KEY_WORDS} ]] && echo -e "${Error} Torrent e palavras-chave bloqueados, não há necessidade de bani-los novamente !" && msg -bar2 && exit 0
	s="A"
	Set_BT
	View_ALL
	echo -e "${Info} Torrent e palavras-chave bloqueados!"
	msg -bar2
}
Ban_SPAM(){
	check_SPAM
	[[ ! -z ${SPAM_PORT} ]] && echo -e "${Error} Porta de SPAM bloqueada detectada, não há necessidade de bloquear novamente !" && msg -bar2 && exit 0
	s="A"
	Set_SPAM
	View_ALL
	echo -e "${Info} Portas de SPAM bloqueadas!"
	msg -bar2
}
Ban_ALL(){
	check_BT
	check_SPAM
	s="A"
	if [[ -z ${BT_KEY_WORDS} ]]; then
		if [[ -z ${SPAM_PORT} ]]; then
			Set_ALL
			View_ALL
			echo -e "${Info} Torrent, palavras-chave e portas de SPAM bloqueadas!"
			msg -bar2
		else
			Set_BT
			View_ALL
			echo -e "${Info} Torrent e palavras-chave bloqueados!"
		fi
	else
		if [[ -z ${SPAM_PORT} ]]; then
			Set_SPAM
			View_ALL
			echo -e "${Info} Porta SPAM (spam) proibida !"
		else
			echo -e "${Error} Torrent, palavras-chave e portas de SPAM bloqueadas,\nnão é necessário banir novamente !" && msg -bar2 && exit 0
		fi
	fi
}
UnBan_BT(){
	check_BT
	[[ -z ${BT_KEY_WORDS} ]] && echo -e "${Error} Torrent e palavras-chave não bloqueadas, confira !"&& msg -bar2 && exit 0
	s="D"
	Set_BT
	View_ALL
	echo -e "${Info} Torrent e palavras-chave desbloqueados !"
	msg -bar2
}
UnBan_SPAM(){
	check_SPAM
	[[ -z ${SPAM_PORT} ]] && echo -e "${Error} Porta SPAM não detectada, verifique !" && msg -bar2 && exit 0
	s="D"
	Set_SPAM
	View_ALL
	echo -e "${Info} Portas de SPAM desbloqueadas !"
	msg -bar2
}
UnBan_ALL(){
	check_BT
	check_SPAM
	s="D"
	if [[ ! -z ${BT_KEY_WORDS} ]]; then
		if [[ ! -z ${SPAM_PORT} ]]; then
			Set_ALL
			View_ALL
			echo -e "${Info} Torrent, palavras-chave e portas de SPAM desbloqueadas !"
			msg -bar2
		else
			Set_BT
			View_ALL
			echo -e "${Info} Torrent, palavras-chave desbloqueadas !"
			msg -bar2
		fi
	else
		if [[ ! -z ${SPAM_PORT} ]]; then
			Set_SPAM
			View_ALL
			echo -e "${Info} Portas de SPAM desbloqueadas !"
			msg -bar2
		else
			echo -e "${Error} Torrent não detectado, palavras-chave e portas de SPAM bloqueadas, verifique !" && msg -bar2 && exit 0
		fi
	fi
}
ENTER_Ban_KEY_WORDS_type(){
	Type=$1
	Type_1=$2
	if [[ $Type_1 != "ban_1" ]]; then
		echo -e "Por favor seleccione um tipo de entrada：
		
 1. Entrada manual (apenas palavras-chave exclusivas são permitidas)
 
 2. Leitura local de arquivos (suporta leitura em lote de palavras-chave, uma palavra-chave por linha)
 
 3. Leitura de endereço de rede (suporta leitura em lote de palavras-chave, uma palavra-chave por linha)" && echo
		read -e -p "(Padrão: 1. Entrada manual):" key_word_type
	fi
	[[ -z "${key_word_type}" ]] && key_word_type="1"
	if [[ ${key_word_type} == "1" ]]; then
		if [[ $Type == "ban" ]]; then
			ENTER_Ban_KEY_WORDS
		else
			ENTER_UnBan_KEY_WORDS
		fi
	elif [[ ${key_word_type} == "2" ]]; then
		ENTER_Ban_KEY_WORDS_file
	elif [[ ${key_word_type} == "3" ]]; then
		ENTER_Ban_KEY_WORDS_url
	else
		if [[ $Type == "ban" ]]; then
			ENTER_Ban_KEY_WORDS
		else
			ENTER_UnBan_KEY_WORDS
		fi
	fi
}
ENTER_Ban_PORT(){
	echo -e "Digite a Porta que você bloqueará:\n(segmento de Porta única /Porta múltipla / Porta continuo)\n"
	if [[ ${Ban_PORT_Type_1} != "1" ]]; then
	echo -e "
	${Green_font_prefix}======== Descrição do exemplo ========${Font_color_suffix}
	
 -Porta única: 25 (porta única)
 
 -Multiporta: 25, 26, 465, 587 (várias portas são separadas por vírgulas)

 -Segmento de porta contínuo: 25:587 (todas as portas entre 25-587)" && echo
	fi
	read -e -p "(Enter é cancelado por padrão):" PORT
	[[ -z "${PORT}" ]] && echo "Cancelado..." && View_ALL && exit 0
}
ENTER_Ban_KEY_WORDS(){
    msg -bar2
	echo -e "Digite as palavras-chave a serem banidas\n(nome de domínio etc suportam apenas uma única palavra-chave)"
	if [[ ${Type_1} != "ban_1" ]]; then
	echo ""
	echo -e "${Green_font_prefix}======== Descrição do exemplo ========${Font_color_suffix}
	
 -alavras-chave: youtube, que proíbe o acesso a qualquer nome de domínio que contenha a palavra-chave youtube.
 
 -Palavras-chave: youtube.com, que proíbe o acesso a qualquer nome de domínio (máscara de nome de domínio pan) que contenha a palavra-chave youtube.com.

 -Palavras-chave: www.youtube.com, que proíbe o acesso a qualquer nome de domínio (máscara de subdomínio) que contenha a palavra-chave www.youtube.com.

 -Mais efeitos de autoteste (como a palavra-chave .zip pode ser usada para desabilitar o download de qualquer arquivo de sufixo .zip)." && echo
	fi
	read -e -p "(Enter é cancelado por padrão):" key_word
	[[ -z "${key_word}" ]] && echo "Cancelado ..." && View_ALL && exit 0
}
ENTER_Ban_KEY_WORDS_file(){
	echo -e "Digite o arquivo de palavra-chave local a ser banido / desbloqueará (usar caminho absoluto)" && echo
	read -e -p "(O padrão é ler key_word.txt no mesmo diretório que o script):" key_word
	[[ -z "${key_word}" ]] && key_word="key_word.txt"
	if [[ -e "${key_word}" ]]; then
		key_word=$(cat "${key_word}")
		[[ -z ${key_word} ]] && echo -e "${Error} O conteúdo do arquivo está vazio. !" && View_ALL && exit 0
	else
		echo -e "${Error} Arquivo não encontrado ${key_word} !" && View_ALL && exit 0
	fi
}
ENTER_Ban_KEY_WORDS_url(){
	echo -e "Insira o endereço do arquivo de rede de palavras-chave a ser banido/desbloqueado (por exemplo, http: //xxx.xx/key_word.txt)" && echo
	read -e -p "(Enter é cancelado por padrão):" key_word
	[[ -z "${key_word}" ]] && echo "Cancelado ..." && View_ALL && exit 0
	key_word=$(wget --no-check-certificate -t3 -T5 -qO- "${key_word}")
	[[ -z ${key_word} ]] && echo -e "${Error} O conteúdo do arquivo de rede está vazio ou o acesso expirou !" && View_ALL && exit 0
}
ENTER_UnBan_KEY_WORDS(){
	View_KEY_WORDS
	echo -e "Digite a palavra-chave que deseja desbloquear (digite a palavra-chave completa e precisa de acordo com a lista acima)" && echo
	read -e -p "(Enter é cancelado por padrão):" key_word
	[[ -z "${key_word}" ]] && echo "Cancelado ..." && View_ALL && exit 0
}
ENTER_UnBan_PORT(){
	echo -e "Digite a porta que deseja descompactar:\n(digite a porta completa e precisa de acordo com a lista acima, incluindo vírgulas, dois pontos)" && echo
	read -e -p "(Enter é cancelado por padrão):" PORT
	[[ -z "${PORT}" ]] && echo "Cancelado ..." && View_ALL && exit 0
}
Ban_PORT(){
	s="A"
	ENTER_Ban_PORT
	Set_PORT
	echo -e "${Info} Porta bloqueada [ ${PORT} ] !\n"
	Ban_PORT_Type_1="1"
	while true
	do
		ENTER_Ban_PORT
		Set_PORT
		echo -e "${Info} Porta bloqueada [ ${PORT} ] !\n"
	done
	View_ALL
}
Ban_KEY_WORDS(){
	s="A"
	ENTER_Ban_KEY_WORDS_type "ban"
	Set_KEY_WORDS
	echo -e "${Info} Palavras-chave bloqueadas [ ${key_word} ] !\n"
	while true
	do
		ENTER_Ban_KEY_WORDS_type "ban" "ban_1"
		Set_KEY_WORDS
		echo -e "${Info} Palavras-chave bloqueadas [ ${key_word} ] !\n"
	done
	View_ALL
}
UnBan_PORT(){
	s="D"
	View_PORT
	[[ -z ${Ban_PORT_list} ]] && echo -e "${Error} Qualquer porta não bloqueada é detectada !" && exit 0
	ENTER_UnBan_PORT
	Set_PORT
	echo -e "${Info} Porta aberta [ ${PORT} ] !\n"
	while true
	do
		View_PORT
		[[ -z ${Ban_PORT_list} ]] && echo -e "${Error} Portas bloqueadas não detectadas !" && msg -bar2 && exit 0
		ENTER_UnBan_PORT
		Set_PORT
		echo -e "${Info} Porta aberta [ ${PORT} ] !\n"
	done
	View_ALL
}
UnBan_KEY_WORDS(){
	s="D"
	Cat_KEY_WORDS
	[[ -z ${Ban_KEY_WORDS_list} ]] && echo -e "${Error}Nenhuma falha detectada !" && exit 0
	ENTER_Ban_KEY_WORDS_type "unban"
	Set_KEY_WORDS
	echo -e "${Info} Palavras-chave desbloqueadas [ ${key_word} ] !\n"
	while true
	do
		Cat_KEY_WORDS
		[[ -z ${Ban_KEY_WORDS_list} ]] && echo -e "${Error} Nenhuma falha detectada !" && msg -bar2 && exit 0
		ENTER_Ban_KEY_WORDS_type "unban" "ban_1"
		Set_KEY_WORDS
		echo -e "${Info} Palavras-chave desbloqueadas [ ${key_word} ] !\n"
	done
	View_ALL
}
UnBan_KEY_WORDS_ALL(){
	Cat_KEY_WORDS
	[[ -z ${Ban_KEY_WORDS_text} ]] && echo -e "${Error} Nenhuma chave detectada, verifique !" && msg -bar2 && exit 0
	if [[ ! -z "${v6iptables}" ]]; then
		Ban_KEY_WORDS_v6_num=$(echo -e "${Ban_KEY_WORDS_v6_list}"|wc -l)
		for((integer = 1; integer <= ${Ban_KEY_WORDS_v6_num}; integer++))
			do
				${v6iptables} -t mangle -D OUTPUT 1
		done
	fi
	Ban_KEY_WORDS_num=$(echo -e "${Ban_KEY_WORDS_list}"|wc -l)
	for((integer = 1; integer <= ${Ban_KEY_WORDS_num}; integer++))
		do
			${v4iptables} -t mangle -D OUTPUT 1
	done
	Save_iptables_v4_v6
	View_ALL
	echo -e "${Info} Todas as palavras-chave foram desbloqueadas !"
}
check_iptables(){
	v4iptables=`iptables -V`
	v6iptables=`ip6tables -V`
	if [[ ! -z ${v4iptables} ]]; then
		v4iptables="iptables"
		if [[ ! -z ${v6iptables} ]]; then
			v6iptables="ip6tables"
		fi
	else
		echo -e "${Error} O firewall do iptables não está instalado!
Por favor, instale o firewall do iptables：
CentOS Sistema： yum install iptables -y
Debian / Ubuntu Sistema： apt-get install iptables -y"
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/sys-on/VPS-MX-8.0/main/SCRIPT/blockBT.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} No se puede vincular a Github !" && exit 0
	wget https://raw.githubusercontent.com/sys-on/VPS-MX-8.0/main/SCRIPT/blockBT.sh -O /etc/ger-frm/blockBT.sh &> /dev/null
	chmod +x /etc/ger-frm/blockBT.sh
	echo -e "O script foi atualizado para a versão mais recente.[ ${sh_new_ver} ]"
	msg -bar2 
	exit 0
}
check_sys
check_iptables
action=$1
if [[ ! -z $action ]]; then
	[[ $action = "banbt" ]] && Ban_BT && exit 0
	[[ $action = "banspam" ]] && Ban_SPAM && exit 0
	[[ $action = "banall" ]] && Ban_ALL && exit 0
	[[ $action = "unbanbt" ]] && UnBan_BT && exit 0
	[[ $action = "unbanspam" ]] && UnBan_SPAM && exit 0
	[[ $action = "unbanall" ]] && UnBan_ALL && exit 0
fi
echo -e "  Painel de Firewall VPS•MX By @Kalix1 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
msg -bar2
echo -e "  ${Green_font_prefix}0.${Font_color_suffix} Veja a lista atual de banidos
————————————
  ${Green_font_prefix}1.${Font_color_suffix} Bloquear Torrent, Palavras-chave
  ${Green_font_prefix}2.${Font_color_suffix} Bloquear Portas de SPAM
  ${Green_font_prefix}3.${Font_color_suffix} Bloquear Torrent, Palavras-chave + Portas de SPAM
  ${Green_font_prefix}4.${Font_color_suffix} Bloquear Porta Personalizada
  ${Green_font_prefix}5.${Font_color_suffix} Bloquear Palavras-chave Personalizadas
————————————
  ${Green_font_prefix}6.${Font_color_suffix} Desbloquear torrent, Palavras-chave
  ${Green_font_prefix}7.${Font_color_suffix} Desbloquear portas de SPAM
  ${Green_font_prefix}8.${Font_color_suffix} Desbloquear Torrent, Palavras-chave, Portas de SPAM
  ${Green_font_prefix}9.${Font_color_suffix} Desbloquear porta Personalizada
 ${Green_font_prefix}10.${Font_color_suffix} Desbloquear palavra-chave Personalizada
 ${Green_font_prefix}11.${Font_color_suffix} Desbloqueie todas as Palavras-chave Personalizadas
————————————
 ${Green_font_prefix}12.${Font_color_suffix} Atualizar script" && msg -bar2
read -e -p " Por favor, coloque um numero [0-12]:" num && msg -bar2
case "$num" in
	0)
	View_ALL
	;;
	1)
	Ban_BT
	;;
	2)
	Ban_SPAM
	;;
	3)
	Ban_ALL
	;;
	4)
	Ban_PORT
	;;
	5)
	Ban_KEY_WORDS
	;;
	6)
	UnBan_BT
	;;
	7)
	UnBan_SPAM
	;;
	8)
	UnBan_ALL
	;;
	9)
	UnBan_PORT
	;;
	10)
	UnBan_KEY_WORDS
	;;
	11)
	UnBan_KEY_WORDS_ALL
	;;
	12)
	Update_Shell
	;;
	*)
	echo "Por favor, digite o número correto[0-12]"
	;;
esac