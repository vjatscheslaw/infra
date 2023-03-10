#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

currentdir=$(pwd)

# if [ -f crlfclean.sh ]; then
#   echo "cleaning files of CRLF"
#   find . -type f -name "*.sh" -exec crlfclean.sh {} \; #clean scripts of Windows' CRLF
# fi

passwd # keep root accessible by setting password

find . -type f -name "*.sh" -exec chmod +x {} \; #make all subsequent scripts in folder executable

#--------------OS SECTION--------------#
#update (Debian)

if [ -f resources/sources.list ]; then
    cat resources/sources.list > /etc/apt/sources.list
fi

#apt update -y && apt upgrade -y
apt update -y && apt upgrade -y
apt install -y curl

adduser vm

mkdir /home/vm/.ssh

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
        cat "$file" >> /home/vm/.ssh/authorized_keys
    fi
done

echo "Total SSH clients added: $clientCount"

if [ -f "/etc/ssh/sshd_config" ]; then
  sed -i 's/^PermitRootLogin[[:space:]]\+[[:graph:]]\{1,\}$/#&/g' /etc/ssh/sshd_config
  sed -i 's/^Port[[:space:]]\+[[:digit:]]\+$/#&/g' /etc/ssh/sshd_config
  sed -i 's/^PermitTunnel[[:space:]]\+[[:digit:]]\+$/#&/g' /etc/ssh/sshd_config
  sed -i 's/^PasswordAuthentication no[[:space:]]\+[[:digit:]]\+$/#&/g' /etc/ssh/sshd_config
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
  echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
  #echo "AllowUsers vm" >> /etc/ssh/sshd_config
  echo "Port 58881" >> /etc/ssh/sshd_config
else
  echo "File sshd_config not found"
fi

systemctl restart sshd

#Network configuration
cp resources/interfaces /etc/networking
systemctl restart networking

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
nft -f resources/nft_tables_chains
apply_nft_rules.sh
make_netfilter_rules_autoload.sh

if [[ $? ]]; then
    echo "Custom firewall systemd service has been created successfully"
else
    echo "Failed to create custom firewall systemd service. Error code $?."
    exit 1
fi

#--------------------------PostgreSQL 14---------------------------#
apt install -y wget gnupg2
wget -q -O postgres14.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc
apt-key add postgres14.asc
bash -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
apt update && apt upgrade -y && apt install -y postgresql-14

if [[ $? ]]; then
    echo "PostgreSQL 14 has been installed successfully"
else
    echo "Failed to install PostgreSQL 14"
    exit 1
fi

#--------------------FreeRADIUS------------------#
apt install -y freeradius
cp -r resources/freeradius/* /etc/freeradius

#systemctl restart freeradius

if [[ $? ]]; then
    echo "Base FreeRADIUS install completed successfully"
else
    echo "Failed to install FreeRADIUS server. Error code $?."
    exit 1
fi

#--------------------DOCKER----------------------#
apt install -y uidmap dbus-user-session fuse-overlayfs slirp4netns
systemctl disable --now docker.service docker.socket

useradd dockermann
passwd dockermann
echo "dockermann:165536:65536" >> /etc/subuid
echo "dockermann:165536:65536" >> /etc/subgid

#No, you can't install rootless docker like this. Without logging in via SSH, without using PAM (look in /etc/ssh/sshd_conf),
#without preliminary installation of openssl-server and rebooting after that, you cannot have access to systemctl --user commands.
#This is why you must run docker.sh script while connected via ssh -p 58881 dockermann@127.0.0.1. And in order to do it, you must temporarily allow password authentication in your /etc/ssh/sshd_config file, despite the default setting above.
#sudo -u dockermann docker.sh

loginctl enable-linger dockermann

mkdir /opt/pgdbdata
chown -R dockermann:dockermann /opt/pgdbdata

mv resources/postgres /home/dockermann/
chown -R dockermann:dockermann /home/dockermann/postgres

cp executables/docker.sh /home/dockermann/
chown -R dockermann:dockermann /home/dockermann

if [[ $? ]]; then
    echo "At this point, you've got SSH access, firewall, network and DNS cache/forwarding server set up successfully. Now, you need to login to dockermann user via ssh, like this: ssh -p 58881 dockermann@127.0.0.1, and execute script docker.sh. If you need rootless docker, at all."
    exit 0
else
    echo "There were errors, which you may need to address manually."
    exit 1
fi

#Further commented out lines are hints for you what to do, before you may restart your freeRADIUS server with systemctl restart freeradius

#su - postgres -c 'cat resources/postgres/pre.sql | psql -p 15432 -h 127.0.0.1'
#su - postgres -c 'cat resources/postgres/radiusdb.sql | psql -h 127.0.0.1 -p 15432 -d radius'

exit 0
