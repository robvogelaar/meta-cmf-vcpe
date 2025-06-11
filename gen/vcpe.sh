#!/bin/bash

source gen-util.sh

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 path/to/vcpe-image-qemux86.lxc.tar.bz2 or user@host:/path/to/vcpe-image-qemux86.lxc.tar.bz2>"
    exit 1
fi

imagefile=$1

# Check if imagefile matches SCP URL pattern (user@host:)
if [[ $imagefile =~ ^[^@]+@[^:]+:.+ ]]; then
    mkdir -p ./tmp
    # Extract filename from path
    filename="${imagefile##*/}"
    if ! scp "$imagefile" "./tmp/$filename"; then
        echo "SCP download failed"
        exit 1
    fi
    imagefile="./tmp/$filename"
fi

# Verify file exists
if [ ! -f "$imagefile" ]; then
    echo "Error: File not found: $imagefile"
    exit 1
fi

#
imagename="${imagefile##*/}"; imagename="${imagename%.tar.bz2}"
containername="vcpe"
profilename="vcpe"
volumename="${containername}-nvram"

#
sudo bridge vlan add vid 100 dev lan-p1 self

# Nvram
if ! lxc storage volume show default $volumename > /dev/null 2>&1; then
    lxc storage volume create default $volumename size=4MiB
fi

lxc image delete ${imagename} 2> /dev/null
lxc image import $imagefile --alias ${imagename}

# Profile
lxc profile create "$profilename" 2>/dev/null || true
lxc profile edit "$profilename" < "$M_ROOT/gen/profiles/$profilename.yaml"

# Initialize the container without starting it
lxc delete ${containername} -f > /dev/null 2>&1
lxc init ${imagename} ${containername} -p ${profilename}

# Create a custom configuration file
cat << EOF > ./vcpe-config.sh
# This is a custom configuration file
CONTAINER_NAME=${containername}
SETUP_DATE=$(date +"%Y-%m-%d_%H:%M:%S")
CUSTOM_CONFIG=true
EOF

# Push the configuration file to the container
lxc file push ./vcpe-config.sh ${containername}/etc/vcpe-config.sh

# Clean up temporary file
rm -f ./vcpe-config.sh

# Now start the container
lxc start ${containername}

