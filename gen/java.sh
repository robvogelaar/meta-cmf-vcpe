#!/bin/bash

source gen-util.sh

check_mld
check_lxd_version
#check_and_create_bridges

container_name="java"
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


lxc file push $MLD/gen/configs/java.eth0.nmconnection ${container_name}/etc/NetworkManager/system-connections/eth0.nmconnection


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

lxc exec ${container_name} -- dnf install -y tar ncurses dnf which procps-ng findutils
lxc exec ${container_name} -- yum install -y wget tcpdump

lxc file push $MLD/gen/configs/simple-service.tar.gz ${container_name}/
lxc exec ${container_name} -- tar xavf /simple-service.tar.gz -C /root
lxc exec ${container_name} -- wget -c https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz -P /root
lxc exec ${container_name} -- tar xavf /root/apache-maven-3.9.9-bin.tar.gz -C /opt
lxc exec ${container_name} -- /opt/apache-maven-3.9.9/bin/mvn -f /root/simple-service/pom.xml clean package

lxc file push $MLD/gen/configs/simple-service.service ${container_name}/etc/systemd/system/
lxc exec ${container_name} -- systemctl daemon-reload
lxc exec ${container_name} -- systemctl enable simple-service
lxc exec ${container_name} -- systemctl start simple-service

