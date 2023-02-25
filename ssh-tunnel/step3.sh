#!/bin/bash
ip addr add 10.0.1.2/24 peer 10.0.1.1 dev tun13
ip link set tun13 up
ip route del default
#route add default gw 10.0.1.1 tun13
ip route add 0/0 via 10.0.1.1
#'X's are your outer gateway (VDS, datacenter, VPN) IP. 'Y''s are your local ISP's gateway IP.
#You definitely don't want to lock yourself out of the tunnel. This is why you leave this route
ip route add XXX.XXX.XXX.XXX via YYY.YYY.YYY.YYY
