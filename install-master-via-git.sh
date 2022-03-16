#!/bin/bash 
## IPs of the worker nodes (passed via API call in postman run sequence)
echo {{node_1_internal_address}} > /run/media/nodes
echo {{node_2_internal_address}} >> /run/media/nodes
echo {{node_3_internal_address}} >> /run/media/nodes
## Install Git and clone scripts for control-plane node
sudo dnf install -y git
sudo dnf install -y wget
sudo wget https://github.com/travistolle/generic-k8s-ibmcloud/blob/main/kubeadm-install-flow.sh -O /run/media/master.sh
sudo chmod +x /run/media/master.sh
sudo /run/media/master.sh