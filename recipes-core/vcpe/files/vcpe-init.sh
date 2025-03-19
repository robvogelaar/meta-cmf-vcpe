#!/bin/sh

. /etc/vcpe-config.sh

HOME=/home/root

#hostname ${CONTAINER_NAME}
#hostname vcpe

# mount rdklogs to tmpfs
mkdir -p /rdklogs
mount -t tmpfs -o size=128m tmpfs /rdklogs

# required for dibbler
mkdir /tmp/dibbler

# prevent multiple syslog/klog
sed -i 's|^/usr/sbin/log_start.sh|#/usr/sbin/log_start.sh|' /etc/utopia/utopia_init.sh

# webpa: eth0 <- erouter0
sed -i 's|eth0|erouter0|' /lib/rdk/parodus_start.sh

# webpa: server ip
sed -i 's|54.166.121.187|10.10.10.210|' /lib/rdk/parodus_start.sh

#
echo 'exit 0' >> /usr/ccsp/wifi/checkwifi.sh

#
logmaxsize=2000000
[ ! -z "${logmaxsize}" ] && sed -i "s/\(maxsize=\"\)[0-9]*\"/\1${logmaxsize}\"/g" /etc/log4crc

#
sed -i '/TRACE/! s/$/\ TRACE/' /etc/debug.ini


if [ ! -f "$HOME/.bashrc" ]; then
    cat > "$HOME/.bashrc" << EOL
# Aliases
alias c="clear && printf '\033[3J'; printf '\033[0m'"

# Host name
#hostname vcpe

# Prompt
PS1='\u@\h:\w\$ '

export SYSTEMD_PAGER=""

EOL
fi

# retrieve bash history
if [ -f /nvram/.bash_history ]; then
    cp /nvram/.bash_history /home/root/
    history -r
fi


# touch /nvram/rtrouted_traffic_monitor

exit 0
