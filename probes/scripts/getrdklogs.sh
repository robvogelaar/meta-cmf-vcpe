#!/bin/bash

if [[ -z "$1" ]]; then
    echo -e "specify mvx container name:\n"
    lxc list --format csv -c ns | grep -E ^mv | cat
    exit 1
fi


create_next_dir() {
    local base_dir="$1"

    # If base directory doesn't exist, create it and return name
    if [ ! -d "$base_dir" ]; then
        mkdir -p "$base_dir"
        basename "$base_dir"
        return 0
    fi

    # Base exists, check for numbered directories
    local counter=1
    while [ $counter -le 999 ]; do
        local padded_num=$(printf "%03d" $counter)
        local new_dir="${base_dir}-${padded_num}"
        local new_name="$(basename ${base_dir})-${padded_num}"

        if [ ! -d "$new_dir" ]; then
            mkdir "$new_dir"
            echo "$new_name"
            return 0
        fi

        counter=$((counter + 1))
    done

    echo "Error: Reached maximum directory number (999)" >&2
    return 1
}


MV=$1

! lxc info "$MV" >/dev/null 2>&1 && { echo "Container $MV does not exist" >&2; exit 1; }
[ "$(lxc list "$MV" --format csv | cut -d',' -f2 | head -n1)" != "RUNNING" ] && { echo "Container $MV is not running" >&2; exit 1; }

export NOW=$(date +%m%d-%H_%M_%S)
avail_dir=$(create_next_dir rdklogs)

lxc exec ${MV} -- mkdir -p /var/tmp/rdklogs-${NOW}/logs
lxc exec ${MV} -- sh -c "cp -a /rdklogs/logs/* /var/tmp/rdklogs-${NOW}/logs/"

lxc exec ${MV} -- cp /tmp/dibbler_erouter0/client.log /var/tmp/rdklogs-${NOW}/logs/dibbler_erouter0-client.log > /dev/null 2>&1
lxc exec ${MV} -- cp /tmp/dibbler_erouter0/envdump /var/tmp/rdklogs-${NOW}/logs/dibbler_erouter0-envdump > /dev/null 2>&1
lxc exec ${MV} -- cp /tmp/dibbler_erouter0/client-notify.log /var/tmp/rdklogs-${NOW}/logs/dibbler_erouter0-client-notify.log > /dev/null 2>&1

lxc exec ${MV} -- cp /tmp/dibbler_mg0/client.log /var/tmp/rdklogs-${NOW}/logs/dibbler_mg0-client.log > /dev/null 2>&1
lxc exec ${MV} -- cp /tmp/dibbler_mg0/envdump /var/tmp/rdklogs-${NOW}/logs/dibbler_mg0-envdump > /dev/null 2>&1
lxc exec ${MV} -- cp /tmp/dibbler_mg0/client-notify.log /var/tmp/rdklogs-${NOW}/logs/dibbler_mg0-client-notify.log > /dev/null 2>&1

lxc exec ${MV} -- cp /tmp/dibbler_voip0/client.log /var/tmp/rdklogs-${NOW}/logs/dibbler_voip0-client.log > /dev/null 2>&1
lxc exec ${MV} -- cp /tmp/dibbler_voip0/envdump /var/tmp/rdklogs-${NOW}/logs/dibbler_voip0-envdump > /dev/null 2>&1
lxc exec ${MV} -- cp /tmp/dibbler_voip0/client-notify.log /var/tmp/rdklogs-${NOW}/logs/dibbler_voip0-client-notify.log > /dev/null 2>&1

lxc exec ${MV} -- cp /var/log/dibbler/dibbler-server.log /var/tmp/rdklogs-${NOW}/logs/ > /dev/null 2>&1

lxc exec ${MV} -- busybox tar czf /var/tmp/rdklogs-${NOW}.tgz -C /var/tmp/rdklogs-${NOW}/logs .
lxc exec ${MV} -- rm -rf /var/tmp/rdklogs-${NOW}/logs

lxc file pull ${MV}/var/tmp/rdklogs-${NOW}.tgz .
lxc exec ${MV} -- rm -rf /var/tmp/rdklogs-${NOW}.tgz

tar xaf rdklogs-${NOW}.tgz -C $avail_dir
rm -rf rdklogs-${NOW}.tgz

echo combining rdklogs
combine-logs.py ${avail_dir}

parse_combinedlogs.py ${avail_dir}/combined_logs.txt.0

#filter-logs.py ${MV}-logs/${NOW}/combined_logs.txt.0
#remove-duplicate-logs.py ${MV}-logs/${NOW}/combined_logs-filtered.txt

lxc console ${MV} --show-log 2>/dev/null > ${avail_dir}/Console.txt

if false;  then
    echo collecting maps
    lxc exec ${MV} -- collect_maps 1> /dev/null
    lxc file pull ${MV}/tmp/proc_maps.txt.gz ${avail_dir}/proc_maps.txt.gz
    gunzip ${avail_dir}/proc_maps.txt.gz
fi

find ${avail_dir} -type f -exec sh -c 'echo "{} ($(stat -c%s "{}" | numfmt --to=iec))"' \; | sort
