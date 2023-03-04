#!/bin/bash
vpn_conf_id=$1
wan_i=$(route -n | awk '$1 == "0.0.0.0" {print $8}')
dns_ip="10.0.0.1"

if [ -z "$vpn_conf_id" ]
then
  vpn_conf_id='wg0'
fi

server_config=/etc/wireguard/${vpn_conf_id}.conf
server_private_key=$(wg genkey)
server_public_key=$(echo "${server_private_key}" | wg pubkey > /etc/wireguard/${vpn_conf_id}_serv_pub_key.key && cat /etc/wireguard/${vpn_conf_id}_serv_pub_key.key)

if [[ -f "${server_config}" ]]; then
  wg-quick down ${vpn_conf_id}
  rm -rf ${server_config}
fi

cat > "${server_config}" <<EOL
[Interface]
Address = 10.0.0.1/24
DNS = ${dns_ip}
SaveConfig = true
ListenPort = 51820
PrivateKey = ${server_private_key}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${wan_i} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${wan_i} -j MASQUERADE
EOL

chown -v root:root ${server_config}
chmod -v 600 ${server_config}

#wg-quick up ${vpn_conf_id}

exit 0
