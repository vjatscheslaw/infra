#!/bin/bash
ip addr add 10.0.1.1/24 peer 10.0.1.2 dev tun13
ip link set tun13 up
