#!/bin/bash 
### Install Git and clone scripts for control node
dnf install -y git
dnf install -y wget
wget https://github.com/travistolle/generic-k8s-ibmcloud/blob/main/kubelet-install-flow.sh -O /root/node.sh
chmod +x /root/node.sh
/root/node.sh
### Set root password so master can use sshpass to send the join cluster command
echo root:glisten-earshot-harbinger-frank3l | chpasswd