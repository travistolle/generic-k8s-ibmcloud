#!/bin/bash 
## IPs of the worker nodes (passed via API call in postman run sequence)
echo {{node_1_internal_address}} > /root/nodes
echo {{node_2_internal_address}} >> /root/nodes
echo {{node_3_internal_address}} >> /root/nodes
export NODE_LIST='/tmp/nodes'
export MASTER_PUBLIC_ADDRESS={{master_public_address}}
## Install Git and clone scripts for control node
dnf install -y Git
wget https://raw.githubusercontent.com/travistolle/generic-k8s-ibmcloud/main/install-k8s-master-rhel8.sh -O /tmp/master.sh
chmod +x /tmp/master.sh
/tmp/master.sh
