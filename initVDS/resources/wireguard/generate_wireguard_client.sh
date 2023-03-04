#!/usr/bin/env bash
# usage:
#     generate_wireguard_client.sh <starting_from_client_index_inclusive> <until_client_index_exclusive> <server_public_key>

if [ $# -lt 3 ]; then
    echo 'USAGE: generate_wireguard_client.sh <starting_from_client_index_inclusive> <until_client_index_exclusive> <server_public_key>'
fi

server_ip=$(hostname -I | awk '{print $1;}')

from=${1:-300}
if [ $from -lt 2 ]; then
echo 'Please stick to range of 2 to 224'
exit 1
fi
to=${2:-$[ $from + 1 ]}
if [ $to -gt 224 ]; then
echo 'Please stick to range of 2 to 224'
exit 1
fi

clients_count=$[ $to - $from ]

systemctl stop wg-quick@wg0
systemctl disable wg-quick@wg0
chmod -v 755 /etc/wireguard/wg0.conf

for i in $(seq 1 "${clients_count}");
do
    client_private_key=$(wg genkey)
    client_public_key=$(echo "${client_private_key}" | wg pubkey)
    client_index=$((i+$from-1))
    client_ip=10.0.0.$(($client_index))/32
    client_config=/etc/wireguard/client$client_index.conf
    echo -e "${client_config}"
  	cat > "${client_config}" <<EOL
[Interface]
PrivateKey = ${client_private_key}
ListenPort = 51820
Address = ${client_ip}
DNS = 10.0.0.1

[Peer]
PublicKey = ${3}
AllowedIPs = 0.0.0.0/0
Endpoint = ${server_ip}:51820
PersistentKeepalive = 21
EOL
    cat >> /etc/wireguard/wg0.conf <<EOL

[Peer]
PublicKey = ${client_public_key}
AllowedIPs = ${client_ip}

EOL
done

chown -v root:root /etc/wireguard/wg0.conf
chmod -v 600 /etc/wireguard/wg0.conf

systemctl enable wg-quick@wg0.service
systemctl restart wg-quick@wg0.service

#reboot

exit 0
