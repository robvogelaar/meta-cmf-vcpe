#!/bin/bash

source gen-util.sh

check_lxd_version
#check_and_create_bridges

container_name="webpa"
image_name="centos9"

########################################################################################
# Obtain the image if it does not exist

if ! lxc image list | grep -q $image_name; then
    echo "Obtaining image: centos/9-Stream"
    lxc image copy images:centos/9-Stream local: --alias $image_name
fi

########################################################################################
# Delete container if exists

if lxc list --format csv | grep -q "^${container_name}"; then
    echo "Deleting ${container_name} container"
    lxc delete ${container_name} -f 1>/dev/null
fi

########################################################################################
# Create the profile

if lxc profile list --format csv | grep -q "^${container_name}"; then
    lxc profile delete ${container_name} 1> /dev/null
fi
lxc profile copy default ${container_name}

cat << EOF | lxc profile edit ${container_name}
name: webpa
description: "webpa"
config:
    boot.autostart: "false"
    limits.cpu: ""            # "" effectively means no CPU limits, allowing access to all available CPUs
    limits.memory: 256MB      # Restrict bng memory usage to 256MB
devices:
    eth0:
        name: eth0
        nictype: bridged
        parent: lxdbr1
        type: nic
        ## ip addressing is static and configured in /etc/network/interfaces
    root:
        path: /
        pool: default
        type: disk
        size: 512MB
EOF

########################################################################################
## set timezone

#lxc profile set ${container_name} environment.TZ $(date +%z | awk '{printf("PST8PDT,M3.2.0,M11.1.0")}')

lxc launch ${image_name} ${container_name} -p ${container_name}

#lxc file push $METAVCPE/gen/configs/webpa.eth0.nmconnection ${container_name}/etc/NetworkManager/system-connections/eth0.nmconnection 1> /dev/null

lxc file push $METAVCPE/gen/configs/webpa.eth0.nmconnection ${container_name}/etc/NetworkManager/system-connections/eth0.nmconnection


lxc exec ${container_name} -- chmod 600 /etc/NetworkManager/system-connections/eth0.nmconnection
lxc exec ${container_name} -- chown root:root /etc/NetworkManager/system-connections/eth0.nmconnection

lxc exec ${container_name} -- systemctl restart NetworkManager

lxc exec ${container_name} -- nmcli connection modify eth0 +ipv4.routes "10.100.200.0/24 10.10.10.100"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv4.routes "10.107.200.0/24 10.10.10.107"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv4.routes "10.108.200.0/24 10.10.10.108"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv4.routes "10.120.200.0/24 10.10.10.120"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv4.routes "10.177.200.0/24 10.10.10.109"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv4.routes "10.178.200.0/24 10.10.10.109"

lxc exec ${container_name} -- nmcli connection modify eth0 +ipv6.routes "2001:dae:0:1::/64 2001:dbf:0:1::100"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv6.routes "2001:dae:7:1::/64 2001:dbf:0:1::107"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv6.routes "2001:dae:8:1::/64 2001:dbf:0:1::108" 
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv6.routes "2001:dae:20:1::/64 2001:dbf:0:1::120"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv6.routes "2001:dbd:0:1::/64 2001:dbf:0:1::109"
lxc exec ${container_name} -- nmcli connection modify eth0 +ipv6.routes "2001:dbe:0:1::/64 2001:dbf:0:1::109"

lxc exec ${container_name} -- nmcli connection up eth0

#exit 0

lxc exec ${container_name} -- dnf install -y ncurses
lxc exec ${container_name} -- yum install -y wget tcpdump

lxc exec ${container_name} -- yum install -y --nogpgcheck https://github.com/xmidt-org/talaria/releases/download/v0.1.3/talaria-0.1.3-1.el7.x86_64.rpm
lxc exec ${container_name} -- yum install -y --nogpgcheck https://github.com/xmidt-org/scytale/releases/download/v0.1.4/scytale-0.1.4-1.el7.x86_64.rpm
lxc exec ${container_name} -- yum install -y --nogpgcheck https://github.com/xmidt-org/tr1d1um/releases/download/v0.1.2/tr1d1um-0.1.2-1.el7.x86_64.rpm


lxc file push $METAVCPE/gen/configs/tr1d1um.yaml ${container_name}/etc/tr1d1um/tr1d1um.yaml
lxc file push $METAVCPE/gen/configs/scytale.yaml ${container_name}/etc/scytale/scytale.yaml
lxc file push $METAVCPE/gen/configs/talaria.yaml ${container_name}/etc/talaria/talaria.yaml

lxc exec ${container_name} -- systemctl start tr1d1um
lxc exec ${container_name} -- systemctl start scytale 
lxc exec ${container_name} -- systemctl start talaria
