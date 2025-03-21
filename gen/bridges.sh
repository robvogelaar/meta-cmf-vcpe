#!/bin/bash

source gen-util.sh

check_and_create_bridges

sudo bridge vlan show dev lan-p1
sudo bridge vlan show dev lan-p2
sudo bridge vlan show dev lan-p3
sudo bridge vlan show dev lan-p4
