#!/bin/bash
source gen-util.sh

if [ -z "${1}" ]; then
    echo "Please provide a mv to connect to, including the lan port number"
    echo "e.g. mv1-r21-7-p1 or mv2plus-r21-7-001-p3 or mv3-r21-9-002-p4"
    echo "or vcpe-p1/2/3/4"
    exit 1
fi

if [[ "${1}" =~ -p([1-4])$ ]]; then
    port="${BASH_REMATCH[1]}"
    trimmed="${1%-p[1-4]}"
else
    echo "Error, Must end with -p1 through -p4"
    exit 1
fi


if [ "${trimmed}" = "vcpe" ]; then
    vlan=100
else
    vlan="$(validate_and_hash "${trimmed}")"
    if [ "${vlan}" = "-1" ]; then
        echo "Error, cannot determine unique vlan"
        exit 1
    fi
fi

container_name="client-${1}"
profile_name="$container_name"
image_alias="alpine"


eth=$(get_eth_interface $1)
parent=$(get_parent_bridge $trimmed $eth)

#echo @eth=$eth
#echo @parent=$parent

# Check if parent starts with 'lan' (it could be 'wanoe')
if [[ ! "$parent" =~ ^lan ]]; then
    echo "$1 is not an available lan port, not creating client" >&2
    exit 1
fi


# Check if local image exists, if not pull and create alias
if ! lxc image list --format csv | grep -q "^${image_alias},"; then
    echo "Obtaining alpine image"
    lxc image copy "images:alpine/3.19" local: --alias "${image_alias}" || {
        echo "Failed to pull image from remote" >&2
        exit 1
    }
fi


# Delete existing container first, then profile
if lxc info "${container_name}" >/dev/null 2>&1; then
    lxc delete -f "${container_name}"
fi

if lxc profile show "${profile_name}" >/dev/null 2>&1; then
    lxc profile delete "${profile_name}" 1> /dev/null
fi

#echo "Creating ${container_name} with vlan ${vlan} on bridge lan-p${port}"

# Create new profile and configure
lxc profile create "${profile_name}" >/dev/null 2>&1 || true
lxc profile device remove "${profile_name}" eth0 >/dev/null 2>&1 || true
lxc profile device remove "${profile_name}" root >/dev/null 2>&1 || true

# Configure network interface
lxc profile device add "${profile_name}" eth0 nic nictype=bridged "parent=lan-p${port}" "vlan=${vlan}" 1> /dev/null
lxc profile device add "${profile_name}" root disk path=/ pool=default 1> /dev/null

# Set basic configuration
lxc profile set "${profile_name}" boot.autostart false
lxc profile set "${profile_name}" limits.memory=128MB
lxc profile set "${profile_name}" limits.cpu=1

# Launch Alpine container using local image
lxc launch "${image_alias}" "${container_name}" "--profile=${profile_name}"
