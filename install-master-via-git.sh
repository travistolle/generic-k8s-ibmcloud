#!/bin/bash 
## IPs of the worker nodes (passed via API call in postman run sequence)
echo {{node_1_internal_address}} > /run/media/nodes
echo {{node_2_internal_address}} >> /run/media/nodes
echo {{node_3_internal_address}} >> /run/media/nodes
## Install Git and clone scripts for control-plane node
dnf install -y git
dnf install -y wget
wget https://github.com/travistolle/generic-k8s-ibmcloud/blob/main/kubeadm-install-flow.sh -O /run/media/master.sh
chmod +x /run/media/master.sh
/run/media/master.sh