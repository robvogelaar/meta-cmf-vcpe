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
# launch container

lxc launch telemetry-base ${container_name} -p ${container_name}

########################################################################################
# reconfigure network

sleep 5

lxc file push "$M_ROOT/gen/configs/telemetry-50-cloud-init.yaml" "${container_name}/etc/netplan/50-cloud-init.yaml" --uid 0 --gid 0 --mode 644

#### echo "+netplan apply"
#### lxc exec ${container_name} -- netplan apply
#### echo "-netplan apply"


lxc exec ${container_name} -- netplan generate
lxc exec ${container_name} -- systemctl restart systemd-networkd


########################################################################################
## set timezone

# lxc exec ${container_name} -- timedatectl set-timezone America/Los_Angeles

########################################################################################
# telemetry-data-collector

lxc exec ${container_name} -- git clone https://github.com/rdkcentral/telemetry-data-collector.git

lxc exec ${container_name} -- sh -c 'cat > /root/telemetry-data-collector/src/main/resources/application.properties << EOF
rdkv.index=rdkv-telemetry
rdkb.index=rdkb-telemetry
elasticsearch.url=http://127.0.0.1:9200/
server.port=8080
EOF'

lxc exec ${container_name} -- sh -c 'cd telemetry-data-collector && mvn clean install'


########################################################################################
# tomcat

lxc exec ${container_name} -- wget -4 -c https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz
lxc exec ${container_name} -- sh -c 'mkdir -p /opt/automatics/ && tar -xf apache-tomcat-9.0.85.tar.gz -C /opt/automatics/'
lxc exec ${container_name} -- cp /root/telemetry-data-collector/target/telemetry-collector.war /opt/automatics/apache-tomcat-9.0.85/webapps/

# Run Tomcat as a systemd service

lxc exec ${container_name} -- bash -c 'cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=root
ExecStart=/opt/automatics/apache-tomcat-9.0.85/bin/startup.sh
ExecStop=/opt/automatics/apache-tomcat-9.0.85/bin/shutdown.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

lxc exec ${container_name} -- systemctl daemon-reload
lxc exec ${container_name} -- systemctl enable tomcat
lxc exec ${container_name} -- systemctl start tomcat


########################################################################################
# elastic

lxc exec ${container_name} -- curl -X PUT "localhost:9200/rdkb-telemetry" \
  -H 'Content-Type: application/json' \
  -d '{
    "mappings": {
      "properties": {
        "Time": {
          "type": "date",
          "format": "yyyy-MM-dd HH:mm:ss"
        }
      }
    }
  }'


########################################################################################
# Test the POST request
#
# lxc exec ${container_name} -- curl -v -X POST "http://localhost:8080/telemetry-collector/rdkb-collector" \
#   -H "Content-Type: application/json" \
#  -d '{"Time": "2025-06-03 23:55:00", "device_id": "test123", "event": "sample_event"}'
#


########################################################################################
# further elastic search instructions

echo
echo "browser http://host:5601"
echo "Go to the menu Stack management →Index patterns. Click on 'Create index pattern'"
echo "Add name as rdkb-telemetry, Select 'Time' from the drop down menu"
echo "You will get a message like this - 'Your index pattern matches 1 source.'"
echo "Click on 'Create index pattern'"
