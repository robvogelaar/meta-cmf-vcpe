#!/bin/bash

# https://wiki.rdkcentral.com/display/RDK/RDKM+Webconfig+Server+Setup

source gen-util.sh

container_name="webconfig-base-container"

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


echo "=== METHOD 1: OpenJDK 11 (Default Repository) ==="
echo ""
echo "# Update package list"
echo "lxc exec \${container_name} -- apt update"
echo ""
echo "# Install OpenJDK 11 (JDK + JRE)"
echo "lxc exec \${container_name} -- apt install -y openjdk-11-jdk"
echo ""
echo "# Verify installation"
echo "lxc exec \${container_name} -- java -version"
echo "lxc exec \${container_name} -- javac -version"
echo ""


# Go installation with proper PATH setup
echo "# 1. GO INSTALLATION (Fixed)"
echo "lxc exec \${container_name} -- wget https://golang.org/dl/go1.20.3.linux-amd64.tar.gz"
echo "lxc exec \${container_name} -- tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz"
echo ""
echo "# Fix: Add Go to PATH"
echo "lxc exec \${container_name} -- bash -c 'echo \"export PATH=\\\$PATH:/usr/local/go/bin\" >> /etc/profile'"
echo "lxc exec \${container_name} -- bash -c 'echo \"export PATH=\\\$PATH:/usr/local/go/bin\" >> ~/.bashrc'"
echo ""
echo "# Test Go installation:"
echo "lxc exec \${container_name} -- /usr/local/go/bin/go version"
echo "# Or with PATH set:"
echo "lxc exec \${container_name} -- bash -c 'source /etc/profile && go version'"
echo ""

# Java (already working)
echo "# 2. JAVA (Already working correctly)"
echo "lxc exec \${container_name} -- java -version"
echo ""

# Cassandra installation (modern approach)
echo "# 3. CASSANDRA INSTALLATION (Modern approach)"
echo ""
echo "# Option A: Using modern GPG key management (Recommended)"
echo "lxc exec \${container_name} -- wget -q -O - https://downloads.apache.org/cassandra/KEYS | gpg --dearmor > /tmp/cassandra.gpg"
echo "lxc exec \${container_name} -- mv /tmp/cassandra.gpg /etc/apt/trusted.gpg.d/"
echo "lxc exec \${container_name} -- echo \"deb https://debian.cassandra.apache.org 41x main\" > /etc/apt/sources.list.d/cassandra.sources.list"
echo ""
echo "# Option B: Your current approach (works but deprecated)"
echo "lxc exec \${container_name} -- bash -c 'echo \"deb https://debian.cassandra.apache.org 41x main\" | tee -a /etc/apt/sources.list.d/cassandra.sources.list'"
echo "lxc exec \${container_name} -- bash -c 'curl https://downloads.apache.org/cassandra/KEYS | apt-key add'"
echo ""
echo "lxc exec \${container_name} -- apt-get update"
echo "lxc exec \${container_name} -- apt-get install -y cassandra"
echo ""

#exit 0

###################################################################################################################################
# Publish the image

lxc stop ${container_name}
lxc image delete webconfig-base 2> /dev/null
lxc publish ${container_name} --alias webconfig-base
lxc delete ${container_name}
