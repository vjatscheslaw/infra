#!/bin/bash
#BEWARE, that you DO NOT NEED to create tun16 manually. It won't work either, even if you do create it.
#The ssh -w must be done with root privileges on both sides of the channel,
#so that the tunnel interface could be created on both client and server (VDS) machines.
#If it isn't happening, you need to switch to `yes` the `AllowTunnel` setting in `/etc/ssh/sshd_config` file, on server side.
#If it doesn't happen, try to reboot VDS server or/and your local network gateway. A good reboot is all what it takes, sometimes 😅
#ip tuntap add mode tun tun16
ip addr add 10.0.2.1/24 peer 10.0.2.2 dev tun16
ip link set tun16 up
