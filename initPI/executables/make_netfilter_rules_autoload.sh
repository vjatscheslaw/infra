#!/usr/bin/env bash

set -e # stop on any error
#set -x # print all commands

# check a user is root
if [ "$(id -u)" != 0 ]; then
  echo Please, run the script as root: \"sudo <path_to_this_script>\"
  exit 1
fi

nft list ruleset > /etc/nftables.conf

touch /etc/network/if-pre-up.d/nftables_cvstom
chmod +x /etc/network/if-pre-up.d/nftables_cvstom

cat > /etc/network/if-pre-up.d/nftables_cvstom << ENDOFFILE
#!/bin/bash
nft -f /etc/nftables.conf
ENDOFFILE

touch /etc/network/if-post-down.d/nftables_cvstom
chmod +x /etc/network/if-post-down.d/nftables_cvstom

cat > /etc/network/if-post-down.d/nftables_cvstom << ENDOFFILE
#!/bin/bash
nft list ruleset > /etc/nftables.conf
ENDOFFILE

exit 0
