#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

# if [ -f crlfclean.sh ]; then
#   echo "cleaning files of CRLF"
#   find . -type f -name "*.sh" -exec crlfclean.sh {} \; #clean scripts of Windows' CRLF
# fi

passwd # keep root accessible by setting password

find . -type f -name "*.sh" -exec chmod +x {} \; #make all subsequent scripts executable

#--------------OS SECTION--------------#
#update (Debian)

if [ -f resources/sources.list ]; then
    cat resources/sources.list > /etc/apt/sources.list
fi

#apt update -y && apt upgrade -y
apt-get update -y && apt-get upgrade -y
apt-get install -y linux-image-amd64 linux-headers-amd64

adduser admin

mkdir /home/admin/.ssh

clientCount=0

for file in resources/clients/*; do
    if [[ -f "$file" ]]; then
        ((clientCount = clientCount + 1))
    fi
done

if [[ clientCount -lt 1 ]]; then
    echo "At least one SSH client public key you need not to lock yourself out. We don't do passwords here."
    exit 1
else
    echo "Added $clientCount clients to authorized SSH users list"
fi

for file in resources/clients/*; do
    if [[ -f "$file" ]]; then
        cat "$file" >> /home/admin/.ssh/authorized_keys
        cat "$file" >> /root/.ssh/authorized_keys
    fi
done

echo "Total SSH clients added: $clientCount"

if [ -f "/etc/ssh/sshd_config" ]; then
  sed -i 's/^PermitRootLogin[[:space:]]\+[[:graph:]]\{1,\}$/#&/g' /etc/ssh/sshd_config
  sed -i 's/^Port[[:space:]]\+[[:digit:]]\+$/#&/g' /etc/ssh/sshd_config
  sed -i 's/^PermitTunnel[[:space:]]\+[[:digit:]]\+$/#&/g' /etc/ssh/sshd_config
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
  echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
  #echo "AllowUsers root admin" >> /etc/ssh/sshd_config
  echo "PermitTunnel yes" >> /etc/ssh/sshd_config
  echo "Port 58883" >> /etc/ssh/sshd_config
else
  echo "File sshd_config not found"
fi

systemctl restart sshd

#One method to run a script from another one is to simply call it as a shell command (like `ls` or `cd`).
#In order to do that, we add our script files to PATH
export PATH=$PATH:$(pwd)/executables

#--------------------DNS---------------------#
unbound.sh

if [[ $? ]]; then
    echo "Unboud DNS server has been initialized successfully"
else
    echo "Failed to initialize Unbound DNS server. Error code $?."
    exit 1
fi

#--------------------FIREWALL-------------------#
netfilter.sh

if [[ $? ]]; then
    echo "Custom firewall systemd service has been created successfully"
else
    echo "Failed to create custom firewall systemd service. Error code $?."
    exit 1
fi

#------------------------VPN--------------------#
wg.sh

if [[ $? ]]; then
    echo "Wireguard VPN server is initialized"
else
    echo "Failed to initialize Wireguard VPN server. Error code $?."
    exit 1
fi

reboot

exit 0
