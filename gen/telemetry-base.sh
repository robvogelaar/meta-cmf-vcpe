#!/bin/bash

# https://wiki.rdkcentral.com/display/RDK/RDKM+Reference+Telemetry+upload+system

source gen-util.sh

container_name="telemetry-base-container"

image_name="ubuntu20.04"

########################################################################################
# obtain the image if it does not exist

if ! lxc image list | grep -q "$image_name"; then
    echo "Obtaining image: ubuntu20.04"
    lxc image copy ubuntu:20.04 local: --alias "$image_name"
fi

########################################################################################
#

lxc delete "${container_name}" -f 2>/dev/null

lxc launch "${image_name}" "${container_name}"

check_network "${container_name}"

###################################################################################################################################
# alias

lxc exec ${container_name} -- sh -c 'echo "alias c=\"clear && printf \\047\\033[3J\\047; printf \\047\\033[0m\\047\"" >> ~/.bashrc'

###################################################################################################################################
# Java nginx maven

lxc exec ${container_name} -- apt update -qq
lxc exec ${container_name} -- apt install -y -qq openjdk-8-jdk
lxc exec ${container_name} -- apt-get install -y -qq nginx maven


###################################################################################################################################
# elasticsearch

lxc exec ${container_name} -- sh -c 'wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -'
lxc exec ${container_name} -- apt-get install apt-transport-https
lxc exec ${container_name} -- sh -c 'echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list'
lxc exec ${container_name} -- apt-get update
lxc exec ${container_name} -- apt-get install -y elasticsearch

lxc exec ${container_name} -- sed -i 's/#network.host: 192.168.0.1/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
lxc exec ${container_name} -- sed -i 's/#http.port: 9200/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
lxc exec ${container_name} -- sed -i '/# --------------------------------- Discovery ----------------------------------/a discovery.type: single-node' /etc/elasticsearch/elasticsearch.yml

lxc exec ${container_name} -- systemctl start elasticsearch.service
lxc exec ${container_name} -- systemctl enable elasticsearch.service


###################################################################################################################################
# kibana

lxc exec ${container_name} -- apt-get install kibana

lxc exec ${container_name} -- sed -i 's/#server.port: 5601/server.port: 5601/' /etc/kibana/kibana.yml
lxc exec ${container_name} -- sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
lxc exec ${container_name} -- sed -i 's/#elasticsearch.hosts: \["http:\/\/localhost:9200"\]/elasticsearch.hosts: ["http:\/\/localhost:9200"]/' /etc/kibana/kibana.yml

lxc exec ${container_name} -- systemctl start kibana
lxc exec ${container_name} -- systemctl enable kibana


#exit 0

###################################################################################################################################
# Publish the image

lxc stop ${container_name}
lxc image delete telemetry-base 2> /dev/null
lxc publish ${container_name} --alias telemetry-base
lxc delete ${container_name}
