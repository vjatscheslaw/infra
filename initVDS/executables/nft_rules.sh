#!/usr/bin/env bash

bash nft_pre.sh
#wait $!

#constants
wan_i=$(route -n | awk '$1 == "0.0.0.0" {print $8}') #find name of our WAN interface
echo "init_fw.sh : WAN network interface is " $wan_i

#general policies
nft add rule inet filter input drop
nft add rule inet filter output accept
nft add rule inet filter forward drop

#not to lock yourself out
nft add rule inet filter input tcp dport 58883 iifname $wan_i accept
#nft add rule inet filter input tcp dport 22 iifname $wan_i accept

#loopback
nft add rule inet filter input iifname "lo" accept
nft add rule inet filter input ip saddr 127.0.0.0/8 drop

#Let ourselves browse Internet
nft add rule inet filter input ct state established,related accept
nft add rule inet filter forward ct state established,related accept

#Defend from SYN flood
nft add rule inet filter input tcp flags syn limit rate 1/second accept
nft add rule inet filter input tcp flags syn drop

#Defend from port scanners
nft add rule inet filter input tcp flags @ (syn|ack|fin|rst) == rst limit rate 1/second accept
nft add rule inet filter input tcp flags @ (syn|ack|fin|rst) == rst drop

#Unbound downstream rules
nft add rule inet filter input ip saddr 10.0.0.0/24 tcp dport 53 ct state new accept
nft add rule inet filter input ip saddr 10.0.0.0/24 udp dport 53 ct state new accept

#Defence against ping of death
nft add rule inet filter input icmp type echo-request limit rate 1/second accept
nft add rule inet filter input icmp type echo-request drop

#Defence against reflection attacks
nft add rule inet filter input udp dport 853 drop

#Limit DNS requests intencity
nft add table inet filter dot_rate_limit
nft add chain inet filter dot_rate_limit { type hash limit { rate 30/second, burst 20, type src } counter packets 0 bytes 0 }
nft add rule inet filter input tcp dport 853 ct state new jump dot_rate_limit
nft add rule inet filter dot_rate_limit limit rate 1/second log prefix "IPTables-Ratelimited: " drop

#Wireguard rules
nft add rule inet filter input udp dport 51820 ct state new accept
