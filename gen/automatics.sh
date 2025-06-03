#!/bin/bash

source gen-util.sh

container_name="automatics"

if ! lxc image list | grep -q "automatics-base"; then
    echo "Creating automatics-base image"
    automatics-base.sh
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
name: automatics
description: "automatics"
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
## set timezone

#lxc profile set ${container_name} environment.TZ $(date +%z | awk '{printf("PST8PDT,M3.2.0,M11.1.0")}')

lxc launch automatics-base ${container_name} -p ${container_name}


lxc file push $M_ROOT/gen/configs/automatics.eth0.nmconnection ${container_name}/etc/NetworkManager/system-connections/eth0.nmconnection
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



lxc exec ${container_name} -- systemctl stop tomcat


###################################################################################################################################
# Install build configure deploy automatics-props

lxc exec ${container_name} -- bash -c 'cd /root && git clone https://code.rdkcentral.com/r/rdk/tools/automatics/automatics-props'
lxc exec ${container_name} -- bash -c "cd /root/automatics-props && /opt/apache-maven-3.9.9/bin/mvn install -q"

lxc exec ${container_name} -- mkdir -p /opt/automatics/apache-tomcat-9.0.102/backup_file/automatics/device
lxc exec ${container_name} -- cp /root/automatics-props/src/automatics.properties /opt/automatics/apache-tomcat-9.0.102/backup_file/automatics
lxc exec ${container_name} -- cp /root/automatics-props/src/device_config.json /opt/automatics/apache-tomcat-9.0.102/backup_file/automatics/device
lxc exec ${container_name} -- mkdir /opt/automatics/apache-tomcat-9.0.102/webapps/automatics
lxc exec ${container_name} -- cp /root/automatics-props/src/automatics.properties /opt/automatics/apache-tomcat-9.0.102/webapps/automatics
lxc exec ${container_name} -- cp /root/automatics-props/src/device_config.json /opt/automatics/apache-tomcat-9.0.102/webapps/automatics
lxc exec ${container_name} -- cp /root/automatics-props/src/config.properties /opt/automatics/apache-tomcat-9.0.102/webapps/automatics
lxc exec ${container_name} -- cp /root/automatics-props/src/user_management.properties /opt/automatics/apache-tomcat-9.0.102/webapps/automatics

lxc exec ${container_name} -- bash -c 'echo "john=b931cd522a614e767bcc48200819c520" > /opt/automatics/apache-tomcat-9.0.102/webapps/automatics/user_management.properties'
lxc exec ${container_name} -- sed -i 's/automatics\.properties\.passcode=/automatics.properties.passcode=YWRtaW46YXV0b21hdGljcw==/' /opt/automatics/apache-tomcat-9.0.102/webapps/automatics/config.properties

lxc exec ${container_name} -- cp /root/automatics-props/target/AutomaticsProps.war /opt/automatics/apache-tomcat-9.0.102/webapps/

###################################################################################################################################
# Install build configure deploy automatics-orchestration

lxc exec ${container_name} -- bash -c 'cd /root && git clone https://code.rdkcentral.com/r/rdk/tools/automatics'
lxc exec ${container_name} -- bash -c "cd /root/automatics && /opt/apache-maven-3.9.9/bin/mvn install -q"

# Create automatics database
lxc exec ${container_name} -- mysql -u root -e "CREATE DATABASE \`automatics\`;"
lxc exec ${container_name} -- mysql -u root automatics -e "SET foreign_key_checks=0; SOURCE /root/automatics/resources/Automatics_RDKB.sql;"
lxc exec ${container_name} -- mysql -u root automatics -e "SET foreign_key_checks=0; SOURCE /root/automatics/resources/Automatics_DB.sql;"
lxc exec ${container_name} -- mysql -u root automatics -e "SET foreign_key_checks=0; SOURCE /root/automatics/resources/Automatics_MySqlProcedures.sql;"

lxc exec ${container_name} -- cp /root/automatics/config/restartTMR.sh /opt/automatics/apache-tomcat-9.0.102/bin
lxc exec ${container_name} -- sed -i 's|JAVA_OPTS="$JAVA_OPTS $JSSE_OPTS"|JAVA_OPTS="$JAVA_OPTS $JSSE_OPTS -DAutomatics -DhibernateUI.config.file=/root/automatics/config/hibernate.cfg.xml -Dlog4j.configurationFile=/root/automatics/target/classes/log4j2-test.xml"|' /opt/automatics/apache-tomcat-9.0.102/bin/catalina.sh
lxc exec ${container_name} -- touch /opt/automatics/apache-tomcat-9.0.102/bin/childUI.jmd and mainUI.jmd
lxc exec ${container_name} -- touch /opt/automatics/apache-tomcat-9.0.102/bin/mainUI.jmd

lxc exec ${container_name} -- cp /root/automatics/releases/Automatics-v3.35/Automatics.war /opt/automatics/apache-tomcat-9.0.102/webapps/


lxc exec ${container_name} -- sed -i 's|<property name="hibernate.connection.driver_class">com.mysql.jdbc.Driver</property>|<property name="hibernate.connection.driver_class">com.mysql.cj.jdbc.Driver</property>|g' /root/automatics/config/hibernate.cfg.xml
lxc exec ${container_name} -- sed -i 's|<property name="hibernate.connection.username"></property>|<property name="hibernate.connection.username">root</property>|g' /root/automatics/config/hibernate.cfg.xml
lxc exec ${container_name} -- sed -i 's|<property name="hibernate.connection.password"></property>|<property name="hibernate.connection.password">cm9vdA==</property>|g' /root/automatics/config/hibernate.cfg.xml


###################################################################################################################################
# Install configure build device-manager

lxc exec ${container_name} -- bash -c 'cd /root && git clone https://code.rdkcentral.com/r/rdk/tools/device-manager'

# Create device_manager database
lxc exec ${container_name} -- mysql -u root -e "CREATE DATABASE \`device_manager\`;"
lxc exec ${container_name} -- mysql -u root device_manager -e "SET foreign_key_checks=0; SOURCE /root/device-manager/src/main/resources/Device_Manager_DB.sql;"
lxc exec ${container_name} -- mysql -u root device_manager -e "ALTER TABLE user_details MODIFY \`PASSWORD\` VARCHAR(75);"
lxc exec ${container_name} -- mysql -u root device_manager -e "UPDATE user_details SET PASSWORD = \"\" WHERE USER_ID = \"admin\";"
lxc exec ${container_name} -- mysql -u root device_manager -e "UPDATE user_details SET EMAIL_ID = \"\" WHERE USER_ID = \"admin\";"
lxc exec ${container_name} -- mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"

# Set the database username (root) and password (root (in base64)) in application.properties
lxc exec ${container_name} -- sed -i 's/spring.datasource.username=/spring.datasource.username=root/' /root/device-manager/src/main/resources/application.properties
lxc exec ${container_name} -- sed -i 's/spring.datasource.password=/spring.datasource.password=cm9vdA==/' /root/device-manager/src/main/resources/application.properties

lxc exec ${container_name} -- bash -c "cd /root/device-manager && /opt/apache-maven-3.9.9/bin/mvn install -q"

###################################################################################################################################
# Install configure build device-manager-ui

lxc exec ${container_name} -- bash -c 'cd /root && git clone https://code.rdkcentral.com/r/rdk/tools/device-manager-ui'
lxc exec ${container_name} -- sed -i 's#DEVICE_MANAGER_BASE_URL=#DEVICE_MANAGER_BASE_URL=http://localhost:8080/DeviceManager/#' /root/device-manager-ui/src/main/resources/application.properties
lxc exec ${container_name} -- bash -c "cd /root/device-manager-ui && /opt/apache-maven-3.9.9/bin/mvn install -q"

###################################################################################################################################
# Deploy device-manager

lxc exec ${container_name} -- cp /root/device-manager/target/device-manager-1.0.5.war /opt/automatics/apache-tomcat-9.0.102/webapps/DeviceManager.war

###################################################################################################################################
# Deploy device-manager-ui

lxc exec ${container_name} -- cp /root/device-manager-ui/target/DeviceManagerUI.war /opt/automatics/apache-tomcat-9.0.102/webapps/

###################################################################################################################################
# Install build automatics-core

lxc exec ${container_name} -- bash -c 'cd /root/ && git clone https://code.rdkcentral.com/r/rdk/tools/automatics/automatics-core'
lxc exec ${container_name} -- bash -c 'cd /root/automatics-core/ && /opt/apache-maven-3.9.9/bin/mvn install -q'

###################################################################################################################################
# Install build rpi-provider

lxc exec ${container_name} -- bash -c 'cd /root/ && git clone https://code.rdkcentral.com/r/rdk/tools/automatics/rpi-provider/java-handler'
lxc exec ${container_name} -- bash -c 'cd /root/java-handler/ && /opt/apache-maven-3.9.9/bin/mvn install -DskipTests -q'

###################################################################################################################################

lxc exec ${container_name} -- systemctl start tomcat
