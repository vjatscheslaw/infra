#!/usr/bin/env bash

#constants
wan_i=$(route -n | awk '$1 == "0.0.0.0" {print $8}') #find name of our WAN interface
echo "init_fw.sh : WAN network interface is " $wan_i

iptables -t filter -F
iptables -t nat -F
iptables -t mangle -F
iptables -t raw -F
iptables -t security -F

ip6tables -t filter -F
ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -t raw -F
ip6tables -t security -F

#not to lock yourself out
iptables -t filter -A INPUT -p tcp -m tcp -i $wan_i --dport 58883 -j ACCEPT
#ip6tables -t filter -A INPUT -p tcp -m tcp -i $wan_i --dport 58883 -j ACCEPT

#general policies
iptables -P INPUT DROP
ip6tables -P INPUT DROP
iptables -P FORWARD DROP
ip6tables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P OUTPUT ACCEPT

#loopback
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j DROP
ip6tables -A INPUT ! -i lo -s ::1/128 -j DROP

#Let ourselves browse Internet
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
ip6tables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

#Defend from SYN flood
iptables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
ip6tables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT
ip6tables -A INPUT -p tcp --syn -j DROP

#Defend from port scanners
iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP
ip6tables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT
ip6tables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP

#Unbound downstream rules (TLS downstream rules (i.e. port 853) are in DOT-RATE-LIMIT section)
iptables -A INPUT -s 10.0.0.0/24 -p tcp -m tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -s 10.0.0.0/24 -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

#Defence against ping of death
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
#ip6tables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
#ip6tables -A INPUT -p icmp --icmp-type echo-request -j DROP

#Defence against reflection attacks
iptables -I INPUT -p udp --dport 853 -j DROP
ip6tables -I INPUT -p udp --dport 853 -j DROP

#Limit DNS requests intensity
iptables -N DOT-RATE-LIMIT
iptables -A DOT-RATE-LIMIT -m hashlimit --hashlimit-mode srcip --hashlimit-upto 30/sec --hashlimit-burst 20 --hashlimit-name dot_conn_rate_limit --jump ACCEPT
iptables -A DOT-RATE-LIMIT -m limit --limit 1/sec --jump LOG --log-prefix "IPTables-Ratelimited: "
iptables -A RATE-LIMIT -j DROP
iptables -I INPUT -p tcp --dport 853 -m conntrack --ctstate NEW -j DOT-RATE-LIMIT
#ip6tables -N DOT-RATE-LIMIT
#ip6tables -A DOT-RATE-LIMIT -m hashlimit --hashlimit-mode srcip --hashlimit-upto 30/sec --hashlimit-burst 20 --hashlimit-name dot_conn_rate_limit --jump ACCEPT
#ip6tables -A DOT-RATE-LIMIT -m limit --limit 1/sec --jump LOG --log-prefix "IPTables-Ratelimited: "
#ip6tables -A RATE-LIMIT -j DROP
#ip6tables -I INPUT -p tcp --dport 853 -m conntrack --ctstate NEW -j DOT-RATE-LIMIT

#Wireguard rules
iptables -A INPUT -p udp -m udp --dport 51820 -m conntrack --ctstate NEW -j ACCEPT

#SSH tunnel rules
iptables -I FORWARD -s 10.0.1.2 -j ACCEPT
iptables -I FORWARD -d 10.0.1.2 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
