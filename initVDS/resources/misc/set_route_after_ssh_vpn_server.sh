#!/bin/bash
ip addr add 10.0.1.1/24 peer 10.0.1.2 dev tun15
ip link set tun15 up
