#!/bin/bash

conf_file=("/etc/zabbix/zabbix_agentd.conf" "/usr/local/etc/zabbix_agentd.conf")

conf_file_path=""

identity=""

file_location_prompt() {
    original_color="$(tput sgr0)"
    red_color="$(tput setaf 1)"
    echo -e "\n\n"
    echo -e "${red_color}"
    echo "================================"
    echo "# zabbix_agentd.conf not found #"
    echo "================================"
    echo -e "${original_color}"
    echo -e "\n\n"
    echo -n "Enter zabbix_agentd.conf location: "
    read user_input
    file_not_found user_input
}


file_not_found() {
    if [ -e "$1" ]; then
        conf_file_path="$1"
    else
        file_location_prompt
    fi
}

Identity_input() {
    echo -n "TLSPSKIdentity= "
    read user_identity_input
    if [ -n "$user_identity_input" ]; then
        identity=$user_identity_input
    else
        echo "Empty identity not allowed"
        Identity_input
    fi
}

for path in "${conf_file[@]}"; do
    if [ -e "$path" ]; then
        conf_file_path="$path"
        break
    fi
done

if [ -z "conf_file_path" ]; then
    file_location_prompt 
fi

tls_state=$(grep "TLSConnect=" $conf_file_path | sed 's/.*=//')

if [[ $tls_state == "unencrypted" ]]; then
    mkdir /home/zabbix
    openssl rand -hex 32 > /home/zabbix/secret.psk
    chown -R zabbix:zabbix /home/zabbix/
    chmod 640 /home/zabbix/secret.psk

    Identity_input

    sed -i '/TLSConnect=/c\TLSConnect=psk' $conf_file_path
    sed -i '/TLSAccept=/c\TLSAccept=psk' $conf_file_path
    sed -i '/TLSPSKFile=/c\TLSPSKFile=/home/zabbix/secret.psk' $conf_file_path
    sed -i "/TLSPSKIdentity=/c\TLSPSKIdentity=$identity" $conf_file_path
    
    systemctl restart zabbix-agent.service

    echo "TLS Key = $(cat /home/zabbix/secret.psk)"
else
    echo "Zabbix agent encryption already setup"
fi