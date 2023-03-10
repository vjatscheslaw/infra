#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

wan_i=$(route -n | awk '$1 == "0.0.0.0" {print $8}') #find name of our WAN interface

apt-get install -y wireguard qrencode

mkdir -p "/etc/wireguard"

server_private_key=$(wg genkey)
server_public_key=$(echo "${server_private_key}" | wg pubkey | tee /etc/wireguard/wg_serv_pub_key.key) #we may try to generate first clients with this public key
server_config=/etc/wireguard/wg0.conf

cat > "${server_config}" <<EOL
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = ${server_private_key}
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${wan_i} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${wan_i} -j MASQUERADE
#PostUp = nft add rule inet filter forward iifname %i accept; nft add rule inet filter forward oifname %i accept; nft add rule inet nat POSTROUTING oifname ${wan_i} masquerade
#PostDown = nft delete inet rule filter forward iifname %i accept; nft delete rule inet filter forward oifname %i accept; nft delete rule inet nat POSTROUTING oifname ${wan_i} masquerade
EOL

chown -v root:root "${server_config}"
chmod -v 600 "${server_config}"

#if [ -f wireguard/generate_wireguard_client.sh ]; then
#    exec ./generate_wireguard_client.sh 1 4 ${server_public_key}
#fi

#Allow packets forwarding in Linux kernel
sysctl net.ipv4.ip_forward=1
sysctl net.ipv6.conf.all.forwarding=1
sysctl net.ipv6.conf.default.forwarding=1
#Persist the setting
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-sysctl.conf
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.d/99-sysctl.conf
echo 'net.ipv6.conf.default.forwarding=1' >> /etc/sysctl.d/99-sysctl.conf

#wg-quick up wg0

systemctl start wg-quick@wg0.service

wg_start_result=$?

if [[ $wg_start_result ]]; then
  echo "The unbound service has been successfully started! Enabling it for autoload"
  systemctl enable wg-quick@wg0.service
else
  echo "Failed to start the unbound service (exit code $wg_start_result)."
  exit 1
fi

exit 0
