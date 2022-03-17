#!/bin/bash 
## IPs of the worker nodes (passed via API call in postman run sequence)
echo {{node_1_internal_address}} > /root/nodes
echo {{node_2_internal_address}} >> /root/nodes
echo {{node_3_internal_address}} >> /root/nodes
## Install Git and clone scripts for control-plane node
yum install -y git
yum install -y wget
mkdir master
cd master
git clone https://github.com/travistolle/generic-k8s-ibmcloud.git
cd generic-k8s-ibmcloud
chmod +x /root/master/generic-k8s-ibmcloud/master.sh
/root/master/generic-k8s-ibmcloud/master.sh