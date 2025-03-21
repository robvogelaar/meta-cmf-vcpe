#!/bin/bash

MV_ROOT="$( dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" )"

if [[ ! "$PWD" == "$MV_ROOT"* ]]; then
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
    echo "Error: Script is being run from a location outside the current directory" >&2
    echo "Current directory: $PWD" >&2
    echo "Script location  : $SCRIPT_PATH" >&2
    echo "Please change your PATH to include the correct directory by:" >&2
    echo "  1. Directly: export PATH=$PWD:\$PATH" >&2
    echo "  2. Permanently: Add 'export PATH=$PWD:\$PATH' to your ~/.bashrc file" >&2
    echo "Then try again." >&2
    exit 1
fi

export MV_ROOT


bridges="
        lxdbr1 \
        wan \
        cm \
        wanoe \
        lan-p1 lan-p2 lan-p3 lan-p4 \
        wlan0 wlan1
    "


check_lxd_version() {
    if command -v lxd &> /dev/null; then
        lxd_version=$(lxd --version)
        major_version=$(echo "$lxd_version" | cut -d. -f1)
        if [[ $major_version -eq 4 ]] || [[ $major_version -eq 5 ]]; then
            #echo "LXD is installed with version $lxd_version."
            :
        else
            #echo "LXD is installed, but the version is not 4 or 5. Current version: $lxd_version."
            :
        fi
    else
        echo "LXD is not installed."
        exit 1
    fi
}


check_network() {
    echo "Waiting for network..."
    attempt=0
    max_attempts=10
    while ! lxc exec $1 -- ping -c 4 8.8.8.8 > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "Network check failed after $max_attempts attempts."
            exit 1
        fi
        #echo "Ping failed, retrying in 1 second..."
        sleep 1
    done
    echo "Network is up."
}


check_devuan_chimaera() {
    # non ubuntu images are no longer (early '24) publically served
    #
    # posted the image on dropbox
    #
    # https://www.dropbox.com/scl/fi/i1amx0tvbd4lygg29o4st/devuan-chimaera.tar.gz?rlkey=9q0mrda1eaohfr85xj2l8zryh&dl=0
    # wget 'https://dl.dropboxusercontent.com/scl/fi/i1amx0tvbd4lygg29o4st/devuan-chimaera.tar.gz?rlkey=9q0mrda1eaohfr85xj2l8zryh&dl=0' -O devuan-chimaera.tar.gz
    # Check if the LXD image with a specific alias exists
    if lxc image list | grep -q "devuan-chimaera-base"; then
        :
        #echo "Image with alias 'devuan-chimaera-base' exists."
    else
        echo "Creating devuan-chimaera-base image"
        url="https://dl.dropboxusercontent.com/scl/fi/i1amx0tvbd4lygg29o4st/devuan-chimaera.tar.gz?rlkey=9q0mrda1eaohfr85xj2l8zryh&dl=0"
        file="$MV_ROOT/tmp/devuan-chimaera.tar.gz"
        [ -e "$encfile" ] || curl -L -o "$file" "$url"
        tar xzf $file -C $MV_ROOT/tmp
        lxc image import $MV_ROOT/tmp/devuan-chimaera $MV_ROOT/tmp/devuan-chimaera.root --alias devuan-chimaera-base
    fi
}


# Validates version string format: name-release-customerid[-index]
# where name=mv1|mv2plus|mv3, release=r21|r22, customerid=7|9|20, index=001-099
# Returns unique hash 1001-3129 or -1 if invalid
# Hash format: name(1-3)release(0-1)custid(0-2)index(00-99)

validate_and_hash() {

    local input="$1"
    local regex="^(mv1|mv2plus|mv3)-r2[12]-(7|9|20)(-0(0[1-9]|[1-9][0-9]))?$"
    # Initial validation
    if [[ ! "$input" =~ $regex ]]; then
        echo "-1"
        return 1
    fi
    # Extract components
    local name=$(echo "$input" | cut -d'-' -f1)
    local release=$(echo "$input" | cut -d'-' -f2)
    local customer_id=$(echo "$input" | cut -d'-' -f3)
    local index=$(echo "$input" | cut -d'-' -f4)
    # Generate name value (1-3)
    local name_val
    case "$name" in
        "mv1") name_val=1 ;;
        "mv2plus") name_val=2 ;;
        "mv3") name_val=3 ;;
    esac
    # Map release to 0-1 position
    local release_num=${release#r}
    local release_position
    case $release_num in
        21) release_position=0 ;;
        22) release_position=1 ;;
        *) echo "-1"
           return 1 ;;
    esac
    # Map customer_id to 0-2 position
    local cust_num=$((10#$customer_id))
    local cust_position
    case $cust_num in
        7) cust_position=0 ;;
        9) cust_position=1 ;;
        20) cust_position=2 ;;
        *) echo "-1"
           return 1 ;;
    esac
    # Validate index if present
    local index_num=0
    if [ ! -z "$index" ]; then
        index_num=$((10#$index))
        if [ $index_num -lt 1 ] || [ $index_num -gt 99 ]; then
            echo "-1"
            return 1
        fi
    fi
    # Generate and return only the hash
    local hash=$((
        (name_val * 1000 +
        release_position * 100 +
        cust_position * 10 +
        index_num) + 1
    ))
    echo "$hash"
    return 0
}


hash_to_string() {
    local hash="$1"

    # Subtract 1 from hash (as per original function)
    ((hash--))

    # Extract components
    local index_num=$((hash % 10))
    local cust_position=$(((hash / 10) % 10))
    local release_position=$(((hash / 100) % 10))
    local name_val=$(((hash / 1000) % 10))

    # Validate ranges
    if [ $name_val -lt 1 ] || [ $name_val -gt 3 ] ||
       [ $release_position -gt 1 ] ||
       [ $cust_position -gt 2 ] ||
       [ $index_num -gt 99 ]; then
        echo "Invalid hash"
        return 1
    fi

    # Convert name_val back to string
    local name
    case "$name_val" in
        1) name="mv1" ;;
        2) name="mv2plus" ;;
        3) name="mv3" ;;
        *) echo "Invalid hash"
           return 1 ;;
    esac

    # Convert release_position back to release number
    local release
    case "$release_position" in
        0) release="r21" ;;
        1) release="r22" ;;
        *) echo "Invalid hash"
           return 1 ;;
    esac

    # Convert cust_position back to customer_id
    local customer_id
    case "$cust_position" in
        0) customer_id="7" ;;
        1) customer_id="9" ;;
        2) customer_id="20" ;;
        *) echo "Invalid hash"
           return 1 ;;
    esac

    # Build the final string
    local result="$name-$release-$customer_id"

    # Add index if present (non-zero)
    if [ $index_num -ne 0 ]; then
        # Format index with leading zeros
        printf -v formatted_index "%02d" $index_num
        result="$result-$formatted_index"
    fi

    echo "$result"
    return 0
}


# Validate container name format
validate_container_name() {
    local name=$1
    local regex="^(mv1|mv2plus|mv3)-r2[12]-(7|9|20)(-0(0[1-9]|[1-9][0-9]))?$"
    [[ $name =~ $regex ]]
    return $?
}


# Generate first MAC address with fixed OUI
generate_mac1() {
    local container_name=$1
    local fixed_oui="00:60:2F"

    # Use md5sum and take first 6 characters
    local hash=$(echo -n "$container_name" | md5sum | cut -c1-6)

    # Convert hash to MAC address format (last 3 bytes)
    local nic_part=$(echo $hash | sed 's/\(..\)/:\1/g' | sed 's/^://')

    # Combine OUI and NIC parts
    echo "${fixed_oui}:${nic_part}"
}


# Generate second MAC address with same OUI but different hash approach
generate_mac2() {
    local container_name=$1
    local fixed_oui="00:60:2F"

    # Use sha256sum and take characters 7-12 for different hash result
    local hash=$(echo -n "$container_name:secondary" | md5sum | cut -c7-12)

    # Convert hash to MAC address format (last 3 bytes)
    local nic_part=$(echo $hash | sed 's/\(..\)/:\1/g' | sed 's/^://')

    # Combine OUI and NIC parts
    echo "${fixed_oui}:${nic_part}"
}


check_and_create_lxdbr1() {

    bridge_name="lxdbr1"
    # Check if the network bridge exists
    if ! lxc network list | grep -q "^| ${bridge_name} "; then
        echo "Bridge ${bridge_name} does not exist. Creating it..."
        # Create the network bridge
        lxc network create ${bridge_name}
    else
        echo "Bridge ${bridge_name} exists. Reapplying settings..."
    fi
    # Set the IPv4 address and disable DHCP
    lxc network set ${bridge_name} ipv4.address "10.10.10.1/24"
    lxc network set ${bridge_name} ipv4.dhcp "false"
    #lxc network set ${bridge_name} ipv4.dhcp.ranges "10.10.10.100-10.10.10.150"
    # Set the IPv6 address and disable DHCP
    lxc network set ${bridge_name} ipv6.address "2001:dbf:0:1::1/64"
    lxc network set ${bridge_name} ipv6.dhcp "false"
    #lxc network set ${bridge_name} ipv6.dhcp.ranges "2001:dbf:0:1::100-2001:dbf:0:1::254"
    lxc network set ${bridge_name} ipv6.dhcp.stateful "true"
    if true; then
        # We need NAT, as this provides the ability to connect to internet from ACS
        # and BNG containers.
        # However we do not want NAT for wan interface on BNG as this prevents ACS
        # connecting to MVx, the 107. address would be replaced by the ip address of
        # the gateway interface.
        # setting nat to true using lxd, would enable NAT for any outgoing interface
        # Create a custom NAT rule that disables NAT for wan interface
        lxc network set ${bridge_name} ipv4.nat "false"
        lxc network set ${bridge_name} ipv6.nat "false"
        ## # Define the rule components
        ## SOURCE_IP="10.10.10.0/24"
        ## OUT_INTERFACE="wan"
        ## TARGET="MASQUERADE"
        ## # Check if the rule exists
        ## if sudo iptables -t nat -C POSTROUTING -s $SOURCE_IP ! -o $OUT_INTERFACE -j $TARGET 2>/dev/null; then
        ##     echo "Bridge ${bridge_name}: NAT rule exists."
        ## else
        ##     echo "Bridge ${bridge_name}: NAT rule does not exist. adding it."
        ##     sudo iptables -t nat -A POSTROUTING -s $SOURCE_IP ! -o $OUT_INTERFACE -j $TARGET
        ## fi
        # Define the rule components
        SOURCE_IP="10.10.10.0/24"
        OUT_INTERFACE="wan"
        TARGET="MASQUERADE"
        DEST_IP="10.10.10.0/24"
        # Check if the rule exists
        if sudo iptables -t nat -C POSTROUTING -s $SOURCE_IP ! -o $OUT_INTERFACE ! -d $DEST_IP -j $TARGET 2>/dev/null; then
            echo "Bridge ${bridge_name}: NAT rule exists."
        else
            echo "Bridge ${bridge_name}: NAT rule does not exist. Adding it."
            sudo iptables -t nat -A POSTROUTING -s $SOURCE_IP ! -o $OUT_INTERFACE ! -d $DEST_IP -j $TARGET
        fi
        #ipv6..
    else
        lxc network set ${bridge_name} ipv4.nat "true"
        lxc network set ${bridge_name} ipv6.nat "true"
    fi
}


check_and_create_wan_bridge() {

    bridge_name=$1

    if ! ip link show type bridge | grep -q "^.* ${bridge_name}:"; then
        echo "Creating bridge: ${bridge_name}"

        if ! sudo ip link add name ${bridge_name} type bridge; then
            echo "Failed to create bridge ${bridge_name}"
            ret=1
        fi
        # Disable IPv6 router advertisements
        if ! sudo sysctl -w net.ipv6.conf.${bridge_name}.accept_ra=0 > /dev/null 2>&1; then
            echo "Warning: Failed to disable IPv6 RA on ${bridge_name}"
        fi
        # Bring bridge up
        if ! sudo ip link set ${bridge_name} up; then
            echo "Failed to bring up bridge ${bridge_name}"
            ret=1
        fi
        # Optional: Enable promiscuous mode and STP
        #sudo ip link set dev "${bridge_name}" promisc on
        #sudo bridge stp "${bridge_name}" on

    else
        echo "Bridge ${bridge_name} exists, flushing IP addresses"
        # Flush existing IP addresses
        if ! sudo ip addr flush dev ${bridge_name}; then
            echo "Warning: Failed to flush IP addresses from ${bridge_name}"
        fi
    fi
}


check_and_create_lan_bridge() {

    bridge_name=$1

    if ! ip link show type bridge | grep -q "^.* ${bridge_name}:"; then
        echo "Creating bridge: ${bridge_name}"

        # Create VLAN-aware bridge
        if ! sudo ip link add name ${bridge_name} type bridge \
            vlan_filtering 1 \
            vlan_default_pvid 1; then
            echo "Failed to create VLAN-aware bridge ${bridge_name}"
            ret=1
        fi
        # Bring bridge up
        if ! sudo ip link set ${bridge_name} up; then
            echo "Failed to bring up bridge ${bridge_name}"
            ret=1
        fi
        # Verify VLAN filtering is enabled
        if ! grep -q "1" /sys/class/net/${bridge_name}/bridge/vlan_filtering 2>/dev/null; then
            echo "Warning: VLAN filtering might not be enabled on ${bridge_name}"
        fi

    else
        echo "Bridge ${bridge_name} exists, flushing IP addresses"
        # Flush existing IP addresses
        if ! sudo ip addr flush dev ${bridge_name}; then
            echo "Warning: Failed to flush IP addresses from ${bridge_name}"
        fi
        # For existing LAN bridges, ensure VLAN filtering is enabled
        if ! grep -q "1" /sys/class/net/${bridge_name}/bridge/vlan_filtering 2>/dev/null; then
            echo "Enabling VLAN filtering on existing bridge ${bridge_name}"
            sudo ip link set ${bridge_name} down
            sudo ip link set ${bridge_name} type bridge vlan_filtering 1
            sudo ip link set ${bridge_name} up
        else
            echo "VLAN filtering is enabled on existing bridge ${bridge_name}"
        fi
    fi
}


check_bridges() {
    missing_bridges=()
    for bridge_name in $bridges; do
        if ! ip link show "$bridge_name" > /dev/null 2>&1; then
            missing_bridges+=("$bridge_name")
        fi
    done

    if [ ${#missing_bridges[@]} -ne 0 ]; then
        echo "Error: The following bridges are missing: ${missing_bridges[*]}"
        echo "Please use the 'bridges' command to verify and create the missing bridges."
        return 1
    else
        return 0
    fi
}


check_and_create_bridges() {

    for bridge_name in $bridges; do
        case "$bridge_name" in

            # lxdbr1
            lxdbr1)
                check_and_create_lxdbr1
                ;;

            # WAN bridges
            wan|cm)
                check_and_create_wan_bridge $bridge_name
                ;;

            # LAN bridges with VLAN support
            lan-p[1-4]|wlan[0-1]|wanoe)
                check_and_create_lan_bridge $bridge_name
                ;;

            *)
                echo "Error: Unsupported bridge name: ${bridge_name}"
                ret=1
                continue
                ;;
        esac
    done
    return $ret
}


# Function to verify bridge configuration
verify_bridge_config() {
    local bridge_name="$1"
    # Check if bridge exists
    if ! ip link show type bridge | grep -q "^.* ${bridge_name}:"; then
        return 1
    fi
    # For LAN bridges, verify VLAN filtering
    if [[ "$bridge_name" =~ ^(lan-p[1-4]|wlan[0-1])$ ]]; then
        if ! grep -q "1" /sys/class/net/${bridge_name}/bridge/vlan_filtering 2>/dev/null; then
            return 1
        fi
    fi
    return 0
}


remove_bridge() {

    bridge_name=$1
    if [[ "$bridge_name" == "lxdbr1" ]]; then
        if lxc network delete "${bridge_name}"; then
            echo "Bridge ${bridge_name} deleted successfully."
        else
            echo "Error: Failed to delete bridge ${bridge_name}."
            lxc network show ${bridge_name}
        fi
    elif ip link show type bridge | grep -q "^.* ${bridge_name}:"; then
        sudo ip link set ${bridge_name} down
        sudo ip link delete ${bridge_name} type bridge
        echo "Bridge ${bridge_name} deleted successfully."
    fi
    if [[ "$bridge_name" == "lxdbr1" ]]; then
        # Define the rule components
        SOURCE_IP="10.10.10.0/24"
        OUT_INTERFACE="wan"
        TARGET="MASQUERADE"
        DEST_IP="10.0.0.0/24"
        # Check if the rule exists
        if sudo iptables -t nat -C POSTROUTING -s $SOURCE_IP ! -o $OUT_INTERFACE ! -d $DEST_IP -j $TARGET 2>/dev/null; then
            echo "Bridge ${bridge_name}: NAT rule exists. Deleting the rule."
            sudo iptables -t nat -D POSTROUTING -s $SOURCE_IP ! -o $OUT_INTERFACE ! -d $DEST_IP -j $TARGET
        else
            echo "Bridge ${bridge_name}: NAT rule does not exist."
        fi
    fi
}


# Function to get parent bridge for a network device in a profile
get_parent_bridge() {
    local profile_name="$1"
    local eth_device="$2"

    # Check if profile exists
    if ! lxc profile show "$profile_name" >/dev/null 2>&1; then
        echo "Error: Profile '$profile_name' not found" >&2
        return 1
    fi

    # Get the parent bridge using yaml path
    local parent
    parent=$(lxc profile show "$profile_name" | awk -v dev="$eth_device" '
        BEGIN { found=0; in_device=0 }
        $1 == "devices:" { in_devices=1 }
        in_devices && $1 == dev":" { found=1; next }
        found && $1 == "parent:" { print $2; exit }
    ')

    if [ -z "$parent" ]; then
        echo "Error: Device '$eth_device' not found in profile '$profile_name' or parent not defined" >&2
        return 1
    fi

    echo "$parent"
    return 0
}

get_eth_interface() {
    local mvstring="$1"
    # Extract MV version and P number using expanded regex to include vcpe
    if [[ "$mvstring" =~ ^(mv[123]|mv2plus)-.*-p([1-4])$ || "$mvstring" =~ ^(vcpe)-p([1-4])$ ]]; then
        local mv_type="${BASH_REMATCH[1]}"
        local p_num="${BASH_REMATCH[2]}"
        # Convert p_num to zero-based index for array access
        local idx=$((p_num - 1))
        
        # Handle different device types
        if [ "$mv_type" = "mv3" ]; then
            # For mv3, eth1..4 based on p1..p4
            echo "eth$((idx + 1))"
        elif [ "$mv_type" = "vcpe" ]; then
            # For vcpe, same as mv3: eth1..4 based on p1..p4
            echo "eth$((idx + 1))"
        else
            # For mv1/mv2plus, eth0..3 based on p1..p4
            echo "eth$idx"
        fi
        return 0
    else
        echo "Error: Invalid format. Expected format like mv1-r21-7-p1, mv2plus-r21-7-001-p3, mv3-r21-9-002-p4, or vcpe-p1" >&2
        return 1
    fi
}

banner() {
    local text="$1"
    local color="${2:-white}"  # Default to white if no color specified
    
    case "$color" in
        "grey")   color_code="\e[30m" ;;
        "red")    color_code="\e[31m" ;;
        "white")  color_code="\e[37m" ;;
        "blue")   color_code="\e[34m" ;;
        "green")  color_code="\e[32m" ;;
        "yellow") color_code="\e[33m" ;;
        *)        color_code="\e[37m" ;; # Default to white
    esac
    
    echo -e "${color_code}${text}\e[0m"
}
