#!/usr/bin/env bash

# move to the directory where the script is located
cd `dirname $0`
CDIR=$(pwd)

source bin/admin-openrc-central.sh

name='img'
basedir=50

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
    --description "Máquina virtual para crear imagen base de Kubernetes" \
    --flavor XL_Plataforma \
    --image jammy-server-cloudimg-amd64 \
    --port port1-k8s-${name} \
    k8s-${name}

#    --user-data k8s-${name}.cfg \
