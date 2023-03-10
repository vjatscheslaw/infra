#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

cat executables/iptables_rules.sh > /usr/local/sbin/init_fw.sh

chmod +x /usr/local/sbin/init_fw.sh

if [ ! -f /usr/local/sbin/init_fw.sh ]; then
    echo "Failed to initialize firewall."
    exit 1
fi

cat > /lib/systemd/system/cvstomfw.service << ENDOFFILE
[Unit]
Description=Custom FW

[Service]
ExecStart=/usr/local/sbin/init_fw.sh

[Install]
WantedBy=network-pre.target
ENDOFFILE

if [ ! -f /lib/systemd/system/cvstomfw.service ]; then
    echo "Failed to create systemd service for loading netfilter rules on system start."
    exit 1
fi

#modprobe xt_limit #for nft netfilter frontend only
#modprobe nf_conntrack_netlink #for nft netfilter frontend only

systemctl start cvstomfw.service
cvstom_fw_start_result=$?

if [[ $cvstom_fw_start_result ]]; then
  echo "The unbound service has been successfully started! Enabling it for autoload"
  systemctl enable cvstomfw.service
else
  echo "Failed to start the unbound service (exit code $cvstom_fw_start_result)."
  exit 1
fi

exit 0
