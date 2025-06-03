#!/bin/bash

source gen-util.sh

container_name="xconf"

if ! lxc image list | grep -q "xconf-base"; then
    echo "Creating xconf-base image"
    xconf-base.sh
fi


########################################################################################
# delete container

lxc delete ${container_name} -f 2>/dev/null

########################################################################################
# create profile

lxc profile delete ${container_name} &> /dev/null

lxc profile copy default ${container_name}

cat << EOF | lxc profile edit ${container_name}
name: xconf
description: "xconf"
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

lxc launch xconf-base ${container_name} -p ${container_name}

########################################################################################
## reconfigure network

sleep 5
lxc file push "$M_ROOT/gen/configs/xconf-50-cloud-init.yaml" "${container_name}/etc/netplan/50-cloud-init.yaml" --uid 0 --gid 0 --mode 644
lxc exec ${container_name} -- netplan apply

########################################################################################
## set timezone

# lxc exec ${container_name} -- timedatectl set-timezone America/Los_Angeles

########################################################################################
## install / start cassandra

lxc exec ${container_name} -- sh -c "
    cd ~ && 
    wget -4 -c https://archive.apache.org/dist/cassandra/3.11.9/apache-cassandra-3.11.9-bin.tar.gz && 
    tar -xf apache-cassandra-3.11.9-bin.tar.gz && 
    start-stop-daemon --start --background --pidfile /var/run/cassandra.pid --make-pidfile --chdir /root/apache-cassandra-3.11.9 --exec /root/apache-cassandra-3.11.9/bin/cassandra -- -R
"

########################################################################################
## install xconf

lxc exec ${container_name} -- sh -c "
    mkdir -p ~/xconf &&
    cd ~/xconf &&
    git clone https://github.com/rdkcentral/xconfserver.git -b main &&
    cd ~/xconf/xconfserver &&
    mvn clean install -DskipTests=true &&
    cat > /root/xconf/xconfserver/xconf-angular-admin/src/main/resources/service.properties << 'EOF'
cassandra.keyspaceName=demo
cassandra.contactPoints=127.0.0.1
cassandra.username=
cassandra.password=
cassandra.port=9042
cassandra.authKey=
 
dataaccess.cache.tickDuration=60000
dataaccess.cache.retryCountUntilFullRefresh=10
dataaccess.cache.changedKeysTimeWindowSize=900000
dataaccess.cache.reloadCacheEntries=false
dataaccess.cache.reloadCacheEntriesTimeout=1
dataaccess.cache.reloadCacheEntriesTimeUnit=DAYS
dataaccess.cache.numberOfEntriesToProcessSequentially=10000
dataaccess.cache.keysetChunkSizeForMassCacheLoad=500
dataaccess.cache.changedKeysCfName=XconfChangedKeys4
EOF
    &&
    cat > /root/xconf/xconfserver/xconf-dataservice/src/main/resources/service.properties << 'EOF'
cassandra.keyspaceName=demo
cassandra.contactPoints=127.0.0.1
cassandra.username=
cassandra.password=
cassandra.port=9042
cassandra.authKey=
dataaccess.cache.tickDuration=60000
dataaccess.cache.retryCountUntilFullRefresh=10
dataaccess.cache.changedKeysTimeWindowSize=900000
dataaccess.cache.reloadCacheEntries=false
dataaccess.cache.reloadCacheEntriesTimeout=1
dataaccess.cache.reloadCacheEntriesTimeUnit=DAYS
dataaccess.cache.numberOfEntriesToProcessSequentially=10000
dataaccess.cache.keysetChunkSizeForMassCacheLoad=500
dataaccess.cache.changedKeysCfName=XconfChangedKeys4
EOF
"


########################################################################################
## set up cassandra database schema

lxc exec ${container_name} -- sh -c "
    ~/apache-cassandra-3.11.9/bin/cqlsh -f ~/xconf/xconfserver/xconf-angular-admin/src/test/resources/schema.cql
"


########################################################################################
## start xconf web application (Angular admin interface with Java backend) running on Jetty as a background service. 

lxc exec ${container_name} -- start-stop-daemon --start --background --make-pidfile \
    --pidfile /var/run/jetty-xconf.pid --chdir /root/xconf/xconfserver/xconf-angular-admin \
    --exec /usr/bin/mvn -- jetty:run \
    -DappConfig=/root/xconf/xconfserver/xconf-angular-admin/src/main/resources/service.properties \
    -f pom.xml

########################################################################################
## start xconf web application (data service with Java backend) running on Jetty as a background service. 

lxc exec ${container_name} -- start-stop-daemon --start --background --make-pidfile \
    --pidfile /var/run/jetty-xconf.pid --chdir /root/xconf/xconfserver/xconf-dataservice \
    --exec /usr/bin/mvn -- jetty:run \
    -DappConfig=/root/xconf/xconfserver/xconf-dataservice/src/main/resources/service.properties \
    -f pom.xml
