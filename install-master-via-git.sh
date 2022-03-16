#!/bin/bash 
## IPs of the worker nodes (passed via API call in postman run sequence)
echo {{node_1_internal_address}} > /tmp/nodes
echo {{node_2_internal_address}} >> /tmp/nodes
echo {{node_3_internal_address}} >> /tmp/nodes
## Install Git and clone scripts for control node
dnf install -y Git
wget https://raw.githubusercontent.com/travistolle/generic-k8s-ibmcloud/main/install-k8s-master-rhel8.sh -O /tmp/master.sh
chmod +x /tmp/master.sh
/tmp/master.sh