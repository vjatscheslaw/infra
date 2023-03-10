#!/bin/bash
#This script is to be run after you create a tunnel with the following command
#ssh -w 15:16 -i /root/.ssh/private.key.file -p 2222 root@100.100.100.5
ip addr add 10.0.2.2/24 peer 10.0.2.1 dev tun15
ip link set tun15 up
ip route del default
ip route add 0/0 via 10.0.2.1 dev tun15
ip route add 78.47.244.214 via 87.248.246.1
