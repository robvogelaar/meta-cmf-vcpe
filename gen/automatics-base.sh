#!/bin/bash

source gen-util.sh

container_name="automatics-base-container"
image_name="centos9"

########################################################################################
# Obtain the image if it does not exist

if ! lxc image list | grep -q $image_name; then
    echo "Obtaining image: centos/9-Stream"
    lxc image copy images:centos/9-Stream local: --alias $image_name
fi

########################################################################################
#
lxc delete ${container_name} -f 2>/dev/null

########################################################################################
#
lxc launch ${image_name} ${container_name}

########################################################################################
#
check_network automatics-base-container

###################################################################################################################################
# alias
lxc exec ${container_name} -- sh -c 'sed -i '\''#alias c=#d'\'' ~/.bashrc && echo '\''alias c="clear && printf \"\033[3J\033[0m\""'\'' >> ~/.bashrc'

###################################################################################################################################
# misc. packages
lxc exec ${container_name} -- dnf install -y tar ncurses dnf which procps-ng findutils git nmap-ncat strace lsof wget tcpdump
lxc exec ${container_name} -- dnf install -y epel-release
lxc exec ${container_name} -- dnf install -y tig

# git config
lxc exec ${container_name} -- git config --global user.name "user"
lxc exec ${container_name} -- git config --global user.email "user@automatics.com"

###################################################################################################################################
# java
lxc exec ${container_name} -- dnf install -y java-17-openjdk java-17-openjdk-devel

###################################################################################################################################
# maven
lxc exec ${container_name} -- wget -c https://dlcdn.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.tar.gz -P /root
lxc exec ${container_name} -- tar xaf /root/apache-maven-3.9.10-bin.tar.gz -C /opt
lxc exec ${container_name} -- bash -c 'echo "export PATH=\$PATH:/opt/apache-maven-3.9.10/bin" > /etc/profile.d/maven.sh'
lxc exec ${container_name} -- chmod +x /etc/profile.d/maven.sh

###################################################################################################################################
# mariaDB
lxc exec ${container_name} -- dnf install -y mariadb-server mariadb
lxc exec ${container_name} -- systemctl start mariadb
lxc exec ${container_name} -- systemctl enable mariadb

###################################################################################################################################
# tomcat
lxc exec ${container_name} -- bash -c '
tomcat_version="9.0.102"
tomcat_filename="apache-tomcat-${tomcat_version}.tar.gz"
tomcat_url="https://archive.apache.org/dist/tomcat/tomcat-9/v${tomcat_version}/bin/${tomcat_filename}"
wget -c --inet4-only "$tomcat_url" -P /root
mkdir -p /opt/automatics/
tar -xf "/root/$tomcat_filename" -C /opt/automatics/
'

# Run tomcat as a systemd service

lxc exec ${container_name} -- bash -c 'cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=root
ExecStart=/opt/automatics/apache-tomcat-9.0.102/bin/startup.sh
ExecStop=/opt/automatics/apache-tomcat-9.0.102/bin/shutdown.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

lxc exec ${container_name} -- systemctl daemon-reload
lxc exec ${container_name} -- systemctl enable tomcat
#### lxc exec ${container_name} -- systemctl start tomcat

###################################################################################################################################
# publish the image
lxc stop ${container_name}

lxc image delete automatics-base 2> /dev/null
lxc publish automatics-base-container --alias automatics-base
lxc delete automatics-base-container
