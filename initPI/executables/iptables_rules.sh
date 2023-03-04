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
iptables -t filter -A INPUT -p tcp -m tcp --dport 58881 -j ACCEPT
#ip6tables -t filter -A INPUT -p tcp -m tcp -i $wan_i --dport 58883 -j ACCEPT

#general policies
iptables -P INPUT DROP
ip6tables -P INPUT DROP
iptables -P FORWARD DROP
ip6tables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P OUTPUT DROP

#loopback
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j DROP
ip6tables -A INPUT ! -i lo -s ::1/128 -j DROP

#Let ourselves browse Internet
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#ip6tables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
#ip6tables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

#Defend from SYN flood
iptables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP
#ip6tables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT
ip6tables -A INPUT -p tcp --syn -j DROP

#Defend from port scanners
#iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP
#ip6tables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j ACCEPT
ip6tables -A INPUT -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP

#Unbound downstream rules (TLS downstream rules (i.e. port 853) are in DOT-RATE-LIMIT section)
iptables -A INPUT -s 66.66.66.0/24 -p tcp -m tcp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -s 66.66.66.0/24 -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT

#Defence against ping of death
#iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
#ip6tables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
#ip6tables -A INPUT -p icmp --icmp-type echo-request -j DROP

