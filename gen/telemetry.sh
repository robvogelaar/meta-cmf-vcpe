#!/bin/bash

source gen-util.sh

container_name="telemetry"

if ! lxc image list | grep -q "telemetry-base"; then
    echo "Creating telemetry-base image"
    telemetry-base.sh
fi


########################################################################################
# delete container

lxc delete ${container_name} -f 2>/dev/null

########################################################################################
# create profile

lxc profile delete ${container_name} &> /dev/null

lxc profile copy default ${container_name}

cat << EOF | lxc profile edit ${container_name}
name: telemetry
description: "telemetry"
config:
    boot.autostart: "false"
    limits.cpu: ""      # "" effectively means no CPU limits, allowing access to all available CPUs
    limits.memory: ""   #
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
        size: 2GiB
EOF

########################################################################################
## launch container

lxc launch telemetry-base ${container_name} -p ${container_name}

########################################################################################
## reconfigure network

sleep 10

lxc file push "$M_ROOT/gen/configs/telemetry-50-cloud-init.yaml" "${container_name}/etc/netplan/50-cloud-init.yaml" --uid 0 --gid 0 --mode 644
lxc exec ${container_name} -- netplan apply

########################################################################################
## set timezone

# lxc exec ${container_name} -- timedatectl set-timezone America/Los_Angeles

