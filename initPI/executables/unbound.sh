#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

#Here, you install your own Certificate Authority onto your linux machine, so that Unbound may continue using list of pre-installed system CAs (the ca-certificate package in Debian). You need to do it on both sides of your DNS-over-TLS Unbound nodes
cp resources/unbound/ca3.pem /usr/local/share/ca-certificates/ca3.crt
update-ca-certificates

#install Unbound
apt-get install -y unbound unbound-host

curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
echo '#!/bin/bash' > /etc/cron.weekly/curl_root_name_hints.sh
echo 'wget https://www.internic.net/domain/named.cache -O /var/lib/unbound/root.hints' >> /etc/cron.weekly/curl_root_name_hints.sh
chmod +x /etc/cron.weekly/curl_root_name_hints.sh

if [ ! -f resources/unbound/unbound.conf ]; then
  echo "Error: unbound.conf file not found in current directory."
  exit 1
fi

cat resources/unbound/unbound.conf > /etc/unbound/unbound.conf

#Something you won't need
mkdir delete
mv /etc/unbound/unbound_control.pem ./delete
mv /etc/unbound/unbound_server.pem ./delete

chown -R unbound:unbound /var/lib/unbound

systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl enable unbound.service
systemctl start unbound.service

exit 0
