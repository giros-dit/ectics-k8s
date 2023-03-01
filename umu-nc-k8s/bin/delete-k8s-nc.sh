#!/usr/bin/env bash

# move to the directory where the script is located
cd `dirname $0`
CDIR=$(pwd)

source bin/admin-openrc-central.sh

NODES='nc2 nc3 nc4'

for name in $NODES; do

    openstack server delete k8s-$name
    openstack port delete port1-k8s-$name

done
