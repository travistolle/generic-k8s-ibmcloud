#cloud-config
runcmd:
 - 'echo {{node_1_internal_address}} > /root/nodes'
 - 'echo {{node_2_internal_address}} >> /root/nodes'
 - 'echo {{node_3_internal_address}} >> /root/nodes'
 - dnf install -y git
 - mkdir /run/mydir
 - cd /run/mydir
 - [ git, clone, "https://github.com/travistolle/generic-k8s-ibmcloud.git" ]
 - [ cp, "/run/mydir/generic-k8s-ibmcloud/kubeadm-install-flow.sh", "/run/mydir/control.sh" ]
 - sleep 60
 - ./control.sh