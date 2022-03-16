#!/bin/bash 
### Install Git and clone scripts for control node
dnf install -y Git
wget https://github.com/travistolle/generic-k8s-ibmcloud/blob/main/kubelet-install-flow.sh -O /tmp/node.sh
chmod +x /tmp/node.sh
/tmp/node.sh
### Set root password so master can use sshpass to send the join cluster command
echo root:glisten-earshot-harbinger-frank3l | chpasswd