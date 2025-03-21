#!/bin/sh
# Example custom script for udhcpc that ignores route updates.
case "$1" in
    deconfig)
        /sbin/ifconfig $interface 0.0.0.0
        ;;
    renew|bound)
        /sbin/ifconfig $interface $ip netmask $subnet
        # Normally, routes would be updated here, but we're ignoring that.
        # Add other configuration handling as needed (e.g., setting DNS).
        ;;
esac
