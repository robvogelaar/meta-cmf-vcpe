#!/bin/sh

source gen-util.sh

check_devuan_chimaera

# create the bng-base-container

lxc delete bng-base-container -f 2> /dev/null

lxc launch devuan-chimaera-base bng-base-container
if [ $? -ne 0 ]; then
    echo "Could not lxc launch devuan-chimaera-base bng-base-container"
    exit 1
fi

check_network bng-base-container

lxc exec bng-base-container -- bash -c " \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y -f \
    \
    vim strace psmisc \
    syslog-ng tcpdump \
    isc-dhcp-server radvd vlan procps \
    iptables iptables-persistent netfilter-persistent \
    resolvconf dnsmasq ntp \
    apache2 ndisc6 iperf3 openssh-server"

lxc exec bng-base-container -- mkdir -p /run/mosquitto
lxc exec bng-base-container -- chown mosquitto:mosquitto /run/mosquitto
lxc exec bng-base-container -- bash -c " \
    apt-get install -y -f \
    \
    mosquitto mosquitto-clients \
    python3-pip && \
    python3 -m pip install paho-mqtt protobuf==3.20.*"

lxc stop bng-base-container

#lxc export bng-base-container bng.rootfs --compression bzip2

lxc image delete bng-base 2> /dev/null
lxc publish bng-base-container --alias bng-base
lxc delete bng-base-container
