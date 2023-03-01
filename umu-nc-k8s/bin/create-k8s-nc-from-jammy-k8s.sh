#!/usr/bin/env bash

# move to the directory where the script is located
cd `dirname $0`
CDIR=$(pwd)

source bin/admin-openrc-central.sh

NODES='nc2 nc3 nc4'

basedir=51
for name in $NODES; do

    # Delete old ssh fingerprints
    ssh-keygen -f "/home/smartmurcia/.ssh/known_hosts" -R "10.20.240.${basedir}"

    # Create server port
    openstack port create \
        --network comun \
	--fixed-ip subnet=comun-subnet,ip-address=10.20.240.$((basedir)) \
        port1-k8s-${name}

    # Create server
    openstack server create \
        --key-name k8s-nc \
        --description "Nodo Kubernetes ${name}" \
        --flavor XL_Plataforma \
        --image jammy-server-cloudimg-amd64-k8s \
        --port port1-k8s-${name} \
        --user-data k8s-${name}.cfg \
        k8s-${name}
    basedir=$((basedir+1))

done
