#!/bin/bash

source gen-util.sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/vcpe-image-qemux86.lxd.tar.bz2 or user@host:/path/to/vcpe-image-qemux86.lxd.tar.bz2>"
    exit 1
fi

input=$1
imagefile=$input

# Check if input matches SCP URL pattern (user@host:/path)
if [[ $input =~ ^[^@]+@[^:]+:.+ ]]; then
    mkdir -p ./tmp
    # Extract filename from path
    filename="${input##*/}"
    if ! scp "$input" "./tmp/$filename"; then
        echo "SCP download failed"
        exit 1
    fi
    imagefile="./tmp/$filename"
fi

# Verify file exists
if [ ! -f "$imagefile" ]; then
    echo "Error: File not found: $imagefile"
    exit 1
fi

imagename="${imagefile##*/}"; imagename="${imagename%.tar.bz2}"
containername="vcpe"
profilename="${containername}"
volumename="${containername}-nvram"

lxc image delete ${imagename} 2> /dev/null
lxc image import $imagefile --alias ${imagename}
lxc delete ${containername} -f > /dev/null 2>&1
lxc profile delete ${profilename} > /dev/null 2>&1
lxc profile copy default ${profilename} > /dev/null 2>&1
cat << EOF | lxc profile edit ${profilename}
name: ${containername}
description: "${containername}"
config:
    boot.autostart: "false"
    security.privileged: "true"
    security.nesting: "true"
    limits.memory: "512MiB"
    limits.memory.swap: "false"
    limits.cpu: "0,1"
devices:
    root:
        path: /
        pool: default
        type: disk
        size: "512MiB"

EOF

# eth0
lxc profile device add ${profilename} eth0 nic nictype=bridged parent=wan name=eth0 hwaddr=00:16:3e:20:79:68

# eth1
lxc profile device add ${profilename} eth1 nic nictype=bridged parent=lan-p1 name=eth1 vlan=100 hwaddr=00:16:3e:16:5f:7c

sudo bridge vlan add vid 100 dev lan-p1 self

lxc profile device add ${profilename} wlan0 nic name=wlan0 nictype=macvlan parent=virt-wlan0
lxc profile device add ${profilename} wlan1 nic name=wlan1 nictype=macvlan parent=virt-wlan1
lxc profile device add ${profilename} wlan2 nic name=wlan2 nictype=macvlan parent=virt-wlan2
lxc profile device add ${profilename} wlan3 nic name=wlan3 nictype=macvlan parent=virt-wlan3

# nvram
if ! lxc storage volume show default $volumename > /dev/null 2>&1; then
    lxc storage volume create default $volumename size=4MiB
fi

lxc profile device add $profilename nvram disk pool=default source=$volumename path=/nvram

lxc profile set ${profilename} environment.TZ $(date +%z | awk '{printf("PST8PDT,M3.2.0,M11.1.0")}')
lxc profile set ${profilename} environment.HOME /home/root
lxc profile set ${profilename} environment.CONTAINER_NAME ${containername}

# Initialize the container without starting it
lxc init ${imagename} ${containername} -p ${profilename}

# Create a custom configuration file
cat << EOF > ./vcpe-config.sh
# This is a custom configuration file
CONTAINER_NAME=${containername}
SETUP_DATE=$(date +"%Y-%m-%d_%H:%M:%S")
CUSTOM_CONFIG=true
EOF

# Push the configuration file to the container
lxc file push ./vcpe-config.sh ${containername}/etc/vcpe-config.sh

# Now start the container
lxc start ${containername}

# Clean up temporary file
rm -f ./vcpe-config.sh
