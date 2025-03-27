#!/bin/bash

source gen-util.sh

if [ -z "$1" ]; then
    echo "Please provide a customer-id 7/9/20 or 8/51/68/69"
    exit 1
fi

check_lxd_version

CUST_ID=$1
container_name="bng-$CUST_ID"


########################################################################################
# Obtain image

if ! lxc image list | grep -q "bng-base"; then
    echo "Creating bng-base image"
    bng-base.sh
fi

########################################################################################
# Delete container if exists

if lxc list --format csv | grep -q "^${container_name}"; then
    echo "Deleting ${container_name}"
    lxc delete ${container_name} -f 1>/dev/null
fi

########################################################################################
# Create the profile

if lxc profile list --format csv | grep -q "^${container_name}"; then
    lxc profile delete ${container_name} 1> /dev/null
fi
lxc profile copy default ${container_name}

cat << EOF | lxc profile edit ${container_name}
name: bng
description: "bng"
config:
    boot.autostart: "false"
    limits.cpu: ""            # "" effectively means no CPU limits, allowing access to all available CPUs
    limits.memory: 256MiB      # Restrict bng memory usage to 256MB
devices:
    eth0:
        name: eth0
        nictype: bridged
        parent: lxdbr1
        type: nic
        ## ip addressing is static and configured in /etc/network/interfaces
    eth1:
        name: eth1
        nictype: bridged
        parent: wan
        type: nic
    eth2:
        name: eth2
        nictype: bridged
        parent: cm
        type: nic
    root:
        path: /
        pool: default
        type: disk
        size: 1GiB
EOF


########################################################################################
## set timezone

lxc profile set ${container_name} environment.TZ $(date +%z | awk '{printf("PST8PDT,M3.2.0,M11.1.0")}')


lxc launch bng-base ${container_name} -p ${container_name}

echo Configuring ${container_name}

########################################################################################
# Upload interfaces files

if [ "$CUST_ID" -eq 6 ] || [ "$CUST_ID" -eq 7 ] || [ "$CUST_ID" -eq 8 ] || [ "$CUST_ID" -eq 9 ] || [ "$CUST_ID" -eq 20 ] || [ "$CUST_ID" -eq 51 ]; then
    lxc file push $M_ROOT/gen/configs/bng-interfaces-cust-$CUST_ID ${container_name}/etc/network/interfaces 1> /dev/null
elif [ "$CUST_ID" -eq 68 ] || [ "$CUST_ID" -eq 69 ]; then
    SINGLE_MULTI_VLAN=single-vlan
    lxc file push $M_ROOT/gen/configs/bng-interfaces-cust-$CUST_ID-$SINGLE_MULTI_VLAN ${container_name}/etc/network/interfaces 1> /dev/null
fi

########################################################################################
# Upload bng dhcp config files

lxc file push $M_ROOT/gen/configs/dhcpd.conf ${container_name}/etc/dhcp/dhcpd.conf 1> /dev/null
lxc file push $M_ROOT/gen/configs/dhcpd6.conf ${container_name}/etc/dhcp/dhcpd6.conf 1> /dev/null

if [ "$CUST_ID" -eq 6 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.106\.|g' /etc/dhcp/dhcpd.conf
    lxc exec ${container_name} -- sed -i 's|2001:dae:0:1|2001:dae:6:1|g' /etc/dhcp/dhcpd6.conf
elif [ "$CUST_ID" -eq 7 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.200\.|10\.107\.200\.|g' /etc/dhcp/dhcpd.conf
    lxc exec ${container_name} -- sed -i 's|10\.100\.201\.|10\.107\.201\.|g' /etc/dhcp/dhcpd.conf
    lxc exec ${container_name} -- sed -i 's|2001:dae:0:1|2001:dae:7:1|g' /etc/dhcp/dhcpd6.conf
    lxc exec ${container_name} -- sed -i 's|2001:daf:0:1|2001:daf:7:1|g' /etc/dhcp/dhcpd6.conf
elif [ "$CUST_ID" -eq 8 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.108\.|g' /etc/dhcp/dhcpd.conf
    lxc exec ${container_name} -- sed -i 's|2001:dae:0:1|2001:dae:8:1|g' /etc/dhcp/dhcpd6.conf
elif [ "$CUST_ID" -eq 9 ]; then
    lxc exec ${container_name} -- ls
elif [ "$CUST_ID" -eq 20 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.120\.|g' /etc/dhcp/dhcpd.conf
    lxc exec ${container_name} -- sed -i 's|2001:dae:0:1|2001:dae:20:1|g' /etc/dhcp/dhcpd6.conf
elif [ "$CUST_ID" -eq 51 ]; then
    lxc exec ${container_name} -- ls
elif [ "$CUST_ID" -eq 68 ]; then
    lxc exec ${container_name} -- ls
elif [ "$CUST_ID" -eq 69 ]; then
    lxc exec ${container_name} -- ls
fi

lxc file push $M_ROOT/gen/configs/dhcpd-notify.sh ${container_name}/etc/dhcpd-notify.sh --mode '755' 1> /dev/null


########################################################################################
# Upload bng radvd config files

lxc file push $M_ROOT/gen/configs/radvd ${container_name}/usr/sbin/radvd --mode '755' 1> /dev/null
lxc file push $M_ROOT/gen/configs/radvd-init ${container_name}/etc/init.d/radvd --mode '755' 1> /dev/null

if [ "$CUST_ID" -eq 6 ] || [ "$CUST_ID" -eq 7 ] || [ "$CUST_ID" -eq 8 ] || [ "$CUST_ID" -eq 9 ] || [ "$CUST_ID" -eq 20 ]|| [ "$CUST_ID" -eq 51 ]; then
    lxc file push $M_ROOT/gen/configs/radvd-cust-$CUST_ID.conf ${container_name}/etc/radvd.conf 1> /dev/null
elif [ "$CUST_ID" -eq 68 ] || [ "$CUST_ID" -eq 69 ]; then
    SINGLE_MULTI_VLAN=single-vlan
    lxc file push $M_ROOT/gen/configs/radvd-cust-$CUST_ID-$SINGLE_MULTI_VLAN.conf ${container_name}/etc/radvd.conf 1> /dev/null
fi

########################################################################################
# Upload bng additional config files

lxc file push $M_ROOT/gen/configs/ntp.conf ${container_name}/etc/ntp.conf 1> /dev/null

lxc file push $M_ROOT/gen/configs/ports.conf ${container_name}/etc/apache2/ports.conf 1> /dev/null

if [ "$CUST_ID" -eq 6 ]; then
    :
elif [ "$CUST_ID" -eq 7 ]; then
    lxc exec ${container_name} -- sed -i 's|10.177.|10.107.|g' /etc/apache2/ports.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbd:0:1|2001:dae:7:1|g' /etc/apache2/ports.conf
elif [ "$CUST_ID" -eq 8 ]; then
    lxc exec ${container_name} -- sed -i 's|10.177.|10.108.|g' /etc/apache2/ports.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbd:0:1|2001:dae:8:1|g' /etc/apache2/ports.conf
elif [ "$CUST_ID" -eq 9 ]; then
    :
elif [ "$CUST_ID" -eq 20 ]; then
    lxc exec ${container_name} -- sed -i 's|10.177.|10.120.|g' /etc/apache2/ports.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbd:0:1|2001:dae:20:1|g' /etc/apache2/ports.conf
elif [ "$CUST_ID" -eq 51 ]; then
    :
elif [ "$CUST_ID" -eq 68 ]; then
    :
elif [ "$CUST_ID" -eq 69 ]; then
    :
fi


########################################################################################
# Upload DCM config file

lxc file push $M_ROOT/gen/configs/DCMresponse.txt ${container_name}/var/www/html/ 1> /dev/null

# Enable and start services
lxc exec ${container_name} -- bash -c "update-rc.d isc-dhcp-server defaults" > /dev/null 2>&1
lxc exec ${container_name} -- bash -c "update-rc.d radvd defaults" > /dev/null 2>&1
lxc exec ${container_name} -- bash -c "update-rc.d mosquitto defaults" > /dev/null 2>&1

lxc exec ${container_name} -- bash -c "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/99-custom.conf"
lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.d/99-custom.conf"


if [ "$CUST_ID" -eq 6 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 7 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 8 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.100.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 9 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.1081.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.881.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.981.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 20 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.100.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 51 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.131.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.121.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.117.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 68 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.100.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.101.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.400.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.200.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
elif [ "$CUST_ID" -eq 69 ]; then
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.100.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.1081.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.881.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
    lxc exec ${container_name} -- bash -c "echo 'net.ipv6.conf.eth1.981.accept_ra=2' >> /etc/sysctl.d/99-custom.conf"
fi


if true; then

    if [ "$CUST_ID" -eq 6 ]; then
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.106.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
    elif [ "$CUST_ID" -eq 7 ]; then
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.107.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.107.201.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
    elif [ "$CUST_ID" -eq 8 ]; then
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.108.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
    elif [ "$CUST_ID" -eq 9 ]; then
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.177.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.178.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.179.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
    elif [ "$CUST_ID" -eq 20 ]; then
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.120.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
    else
        lxc exec ${container_name} -- bash -c "iptables -t nat -A POSTROUTING -s 10.100.200.0/24 -o eth0 ! -d 10.10.10.0/24 -j MASQUERADE"
    fi

    lxc exec ${container_name} -- bash -c "sudo sh -c 'iptables-save > /etc/iptables/rules.v4'"
    lxc exec ${container_name} -- bash -c "sudo sh -c 'ip6tables-save > /etc/iptables/rules.v6'"


    # Create and upload the VLAN init script
    cat << EOF > $M_ROOT/gen/configs/iptables-restore
#!/bin/sh
### BEGIN INIT INFO
# Provides:          iptables-restore
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Restore iptables rules
### END INIT INFO

iptables-restore < /etc/iptables/rules.v4
ip6tables-restore < /etc/iptables/rules.v6
EOF

    lxc file push $M_ROOT/gen/configs/iptables-restore ${container_name}/etc/init.d/iptables-restore --mode '755' 1> /dev/null

    rm $M_ROOT/gen/configs/iptables-restore

    lxc exec ${container_name} -- bash -c "update-rc.d iptables-restore defaults" > /dev/null 2>&1
fi


########################################################################################
# a payload for http
lxc exec ${container_name} -- bash -c "dd if=/dev/random of=/var/www/html/random-5MB-2302.2_2023-04-13T14-21-49.pkgtb bs=1M count=5"

########################################################################################
# dnsmasq

lxc file push $M_ROOT/gen/configs/dnsmasq-instance-erouter0.conf ${container_name}/etc/ 1> /dev/null
lxc file push $M_ROOT/gen/configs/dnsmasq-instance-mg0.conf ${container_name}/etc/ 1> /dev/null

lxc file push $M_ROOT/gen/configs/dnsmasq-instance-erouter0.hosts ${container_name}/etc/ 1> /dev/null
lxc file push $M_ROOT/gen/configs/dnsmasq-instance-mg0.hosts ${container_name}/etc/ 1> /dev/null

if [ "$CUST_ID" -eq 6 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.106\.|g' /etc/dnsmasq-instance-erouter0.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbe:0:1|2001:dae:6:1|g' /etc/dnsmasq-instance-erouter0.conf

elif [ "$CUST_ID" -eq 7 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.107\.|g' /etc/dnsmasq-instance-erouter0.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbe:0:1|2001:dae:7:1|g' /etc/dnsmasq-instance-erouter0.conf
    lxc exec ${container_name} -- sed -i 's|10\.177\.|10\.107\.|g' /etc/dnsmasq-instance-erouter0.hosts
    lxc exec ${container_name} -- sed -i 's|2001:dbd:0:1::129|2001:dae:7:1::129|g' /etc/dnsmasq-instance-erouter0.hosts

elif [ "$CUST_ID" -eq 8 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.108\.|g' /etc/dnsmasq-instance-erouter0.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbe:0:1|2001:dae:8:1|g' /etc/dnsmasq-instance-erouter0.conf
elif [ "$CUST_ID" -eq 9 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.178\.|g' /etc/dnsmasq-instance-erouter0.conf
elif [ "$CUST_ID" -eq 20 ]; then
    lxc exec ${container_name} -- sed -i 's|10\.100\.|10\.120\.|g' /etc/dnsmasq-instance-erouter0.conf
    lxc exec ${container_name} -- sed -i 's|2001:dbe:0:1|2001:dae:20:1|g' /etc/dnsmasq-instance-erouter0.conf
    lxc exec ${container_name} -- sed -i 's|10\.177\.|10\.120\.|g' /etc/dnsmasq-instance-erouter0.hosts
    lxc exec ${container_name} -- sed -i 's|2001:dbd:0:1::129|2001:dbf:0:1::120|g' /etc/dnsmasq-instance-erouter0.hosts

elif [ "$CUST_ID" -eq 51 ]; then
    lxc exec ${container_name} -- ls
elif [ "$CUST_ID" -eq 68 ]; then
    lxc exec ${container_name} -- ls
elif [ "$CUST_ID" -eq 69 ]; then
    lxc exec ${container_name} -- ls
fi


lxc exec ${container_name} -- mkdir /etc/dnsmasq-instance-erouter0.d
lxc file push $M_ROOT/gen/configs/dnsmasq-instance-erouter0 ${container_name}/etc/init.d/ --mode '755' 1> /dev/null
lxc exec ${container_name} -- bash -c "update-rc.d dnsmasq-instance-erouter0 defaults" > /dev/null 2>&1

if [ "$CUST_ID" -eq 9 ]; then
    lxc exec ${container_name} -- mkdir /etc/dnsmasq-instance-mg0.d
    lxc file push $M_ROOT/gen/configs/dnsmasq-instance-mg0 ${container_name}/etc/init.d/ --mode '755' 1> /dev/null
    lxc exec ${container_name} -- bash -c "update-rc.d dnsmasq-instance-mg0 defaults" > /dev/null 2>&1
fi

lxc exec ${container_name} -- bash -c "update-rc.d dnsmasq disable" > /dev/null 2>&1

########################################################################################
# mosquitto

lxc file push $M_ROOT/gen/configs/mosquitto.conf ${container_name}/etc/mosquitto/ 1> /dev/null
lxc exec ${container_name} -- bash -c "sed -i '/PIDFILE=\/run\/mosquitto\/mosquitto.pid/a mkdir -p /run/mosquitto' /etc/init.d/mosquitto"

lxc file push $M_ROOT/gen/usp-controller/usp_msg_1_2_pb2.py ${container_name}/root/ 1> /dev/null
lxc file push $M_ROOT/gen/usp-controller/usp_record_1_2_pb2.py ${container_name}/root/ 1> /dev/null
lxc file push $M_ROOT/gen/usp-controller/mqtt-usp-client.py ${container_name}/root/ 1> /dev/null


########################################################################################
# iperf3 server

lxc file push $M_ROOT/gen/configs/iperf3-server ${container_name}/etc/init.d/ 1> /dev/null
lxc exec ${container_name} -- bash -c "chmod +x /etc/init.d/iperf3-server"
lxc exec ${container_name} -- bash -c "update-rc.d iperf3-server defaults" > /dev/null 2>&1


########################################################################################
## # add a user
## lxc exec bng -- sh -c 'adduser --disabled-password --gecos "" tester'
## lxc exec bng -- sh -c 'echo "tester:tester" | chpasswd'


## Add an alias
lxc exec ${container_name} -- bash -c "echo \"alias c='clear && printf '\\''\033[3J'\\''; printf '\\''\033[0m'\\'''\" >> /root/.bashrc"


########################################################################################
# disable root password
lxc exec ${container_name} -- bash -c "sed -i 's/^root:x:/root::/' /etc/passwd"

########################################################################################
# enable console
lxc exec ${container_name} -- bash -c "sed -i 's/#1:2345:respawn:\/sbin\/getty --noclear 38400 tty1/1:2345:respawn:\/sbin\/getty --noclear 38400 console/' /etc/inittab"

########################################################################################
########################################################################################

echo "Restarting ${container_name}"
lxc restart ${container_name}
