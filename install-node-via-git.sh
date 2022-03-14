#!/bin/bash 
## Install Git and clone scripts for control node
dnf install -y Git
wget https://raw.githubusercontent.com/travistolle/generic-k8s-ibmcloud/main/install-k8s-worker-node-rhel8.sh -O /tmp/master.sh
chmod +x /tmp/node.sh
/tmp/node.sh