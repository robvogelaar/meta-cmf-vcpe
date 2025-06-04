#!/bin/sh

if [[ -z "$1" ]]; then
    echo -e "specify container name, available vcpe containers:\n"
    lxc list --format csv -c ns | grep -E ^vcpe | cat
    exit 1
fi

container=$1

! lxc info "${container}" >/dev/null 2>&1 && { echo "Container ${container} does not exist" >&2; exit 1; }
[ "$(lxc list "${container}" --format csv | cut -d',' -f2 | head -n1)" != "RUNNING" ] && { echo "Container ${container} is not running" >&2; exit 1; }


lxc file pull ${container}/version.txt version.txt 2> /dev/null

lxc file pull ${container}/home/root/rssfree.log rssfree-${container}.log 2> /dev/null

#lxc file pull ${container}/tmp/syscfg.log syscfg-${container}.log 2> /dev/null
#lxc file pull ${container}/tmp/sysevent.log sysevent-${container}.log 2> /dev/null
#lxc file pull ${container}/tmp/rtrouted_traffic_monitor rbus-${container}.log 2> /dev/null

if false; then
    lxc file pull ${container}/tmp/runner.log . 2> /dev/null
    lxc file pull ${container}/tmp/mark.log . 2> /dev/null
    lxc file pull ${container}/tmp/pcap-eth0.pcap . 2> /dev/null
    lxc file pull ${container}/tmp/pcap-vrf-mg0.pcap . 2> /dev/null
    lxc file pull ${container}/tmp/sniff-eth0.log . 2> /dev/null
    lxc file pull ${container}/tmp/sniff-vrf-mg0.log . 2> /dev/null
    lxc file pull ${container}/tmp/interfacesv4.log . 2> /dev/null
    lxc file pull ${container}/tmp/interfacesv6.log . 2> /dev/null
    lxc file pull ${container}/tmp/routesv4.log . 2> /dev/null
    lxc file pull ${container}/tmp/routesv6.log . 2> /dev/null
    lxc file pull ${container}/tmp/rulesv4.log . 2> /dev/null
    lxc file pull ${container}/tmp/rulesv6.log . 2> /dev/null
    lxc file pull ${container}/tmp/files-resolv.conf.log . 2> /dev/null
fi

find -maxdepth 1 -type f -name '*.log' | sort

if false; then
    find -maxdepth 1 -type f -name '*.pcap' | sort
fi

[ -f "rssfree-${container}.log" ] && parse-rssfree-log.py rssfree-${container}.log

#[ -f "syscfg-${container}.log" ] && parse-syscfg-log.py syscfg-${container}.log
#[ -f "sysevent-${container}.log" ] && parse-sysevent-log.py sysevent-${container}.log
#[ -f "sysevent-${container}.log" ] && parse-sysevent-map.py sysevent-${container}.log && rm -rf *.dot || rm -rf *.dot
#[ -f "rbus-${container}.log" ] && parse-rbus-log.py rbus-${container}.log
