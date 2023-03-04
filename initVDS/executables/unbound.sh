#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

cp resources/unbound/ca3.pem /usr/local/share/ca-certificates/ca3.crt
update-ca-certificates

#install Unbound
apt-get install -y unbound unbound-host

curl -o /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
echo '#!/bin/bash' > /etc/cron.monthly/curl_root_name_hints.sh
echo 'wget https://www.internic.net/domain/named.cache -O /var/lib/unbound/root.hints' >> /etc/cron.monthly/curl_root_name_hints.sh
chmod +x /etc/cron.monthly/curl_root_name_hints.sh

if [ ! -f resources/unbound/unbound.conf ]; then
  echo "Error: unbound.conf file not found in current directory."
  exit 1
fi

cat resources/unbound/unbound.conf > /etc/unbound/unbound.conf
cp resources/unbound/private/unbound.key.pem /etc/unbound/
cp resources/unbound/unbound.pub.pem /etc/unbound/
mkdir delete
mv /etc/unbound/unbound_control.pem ./delete
mv /etc/unbound/unbound_server.pem ./delete

chown -R unbound:unbound /var/lib/unbound

systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl enable unbound.service
systemctl start unbound.service

exit 0
