#!/bin/bash 

NOM=`less /etc/newadm/ger-user/nombre.log`
NOM1=`echo $NOM`
notify -i "⚠️ A VPS: $NOM1 FOI REINICIAR ⚠️" -t "❗️A reinicialização foi ✅BEM-SUCEDIDA✅❗️"



