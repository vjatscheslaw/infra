#!/bin/bash
ip route del default
#'Y's are your local ISP's gateway IP address
ip route add 0/0 via YYY.YYY.YYY.YYY
