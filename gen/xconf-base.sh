#!/bin/bash

# https://wiki.rdkcentral.com/display/RDK/Xconf+Server+-+User+guide+for+configuration+and+feature+validation

source gen-util.sh

container_name="xconf-base-container"

image_name="ubuntu18.04"

########################################################################################
# obtain the image if it does not exist

if ! lxc image list | grep -q "$image_name"; then
    echo "Obtaining image: ubuntu18.04"
    lxc image copy ubuntu:18.04 local: --alias "$image_name"
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
# Java Maven Python2.7

lxc exec ${container_name} -- apt update -qq
lxc exec ${container_name} -- apt install -y -qq openjdk-8-jdk
lxc exec ${container_name} -- apt install -y -qq maven python2.7

###################################################################################################################################
# Publish the image

lxc stop ${container_name}
lxc image delete xconf-base 2> /dev/null
lxc publish ${container_name} --alias xconf-base
lxc delete ${container_name}
