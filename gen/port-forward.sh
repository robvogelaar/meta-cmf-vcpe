#!/bin/bash

###############################################################################################
# acs:
#       10.10.10.200 | 2001:dbf:0:1::200 (eth0)
#       ssh -L 192.168.2.120:8888:10.10.10.200:80 rev@192.168.2.120
#
# ui:
#       http://192.168.2.120:8888
#
###############################################################################################
# webpa:
#       10.10.10.210 | 2001:dbf:0:1::210 (eth0)
#
###############################################################################################
# oktopus:
#       10.10.10.220 | 2001:dbf:0:1::220 (eth0)
#       ssh -L 192.168.2.120:7777:10.10.10.220:80 rev@192.168.2.120
#
# ui:
#       http://192.168.2.120:7777
#
###############################################################################################
# automatics:
#       10.10.10.240 | 2001:dbf:0:1::240 (eth0)
#       ssh -L 192.168.2.120:5555:10.10.10.240:8080 rev@192.168.2.120
#
# automatics-orchestration:
#
# automatics-props:
#       http://192.168.2.120:5555/AutomaticsProps/automatics/props
#       http://192.168.2.120:5555/AutomaticsProps/automatics/deviceConfig
#
# device manager:
#       http://192.168.2.120:5555/DeviceManagerUI/login.html
#       http://192.168.2.120:5555/DeviceManager/swagger-ui.html
#
###############################################################################################
# xconf:
#       10.10.10.250 | 2001:dbf:0:1::250 (eth0)
#       ssh -L 192.168.2.120:19093:10.10.10.250:19093 rev@192.168.2.120
#
# ui:
#       http://192.168.2.120:19093
#
###############################################################################################
# telemetry:
#       10.10.10.251 | 2001:dbf:0:1::251 (eth0)
#       ssh -L 192.168.2.120:5601:10.10.10.251:5601 rev@192.168.2.120
#
# ui (elastic):
#       http://192.168.2.120:5601
#


# Check if username and host are provided as command line arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <host>"
    echo "Example: $0 rev 192.168.2.120"
    exit 1
fi

username=$1
host=$2

# Create SSH tunnel with multiple port forwards
echo "Creating SSH tunnels..."
echo "ACS UI will be available at: http://$host:8888"
echo "Oktopus UI will be available at: http://$host:7777"
echo "Automatics UI will be available at: http://$host:5555"
echo "XConf UI will be available at: http://$host:19093"
echo "Telemetry UI will be available at: http://$host:5601"
echo ""

ssh -L $host:8888:10.10.10.200:80 \
    -L $host:7777:10.10.10.220:80 \
    -L $host:5555:10.10.10.250:8080 \
    -L $host:19093:10.10.10.250:19093 \
    -L $host:5601:10.10.10.251:5601 \
    $username@$host
