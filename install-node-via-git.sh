#cloud-config
runcmd:
 - dnf install -y git
 - mkdir /run/mydir
 - cd /run/mydir
 - [ git, clone, "https://github.com/travistolle/generic-k8s-ibmcloud.git" ]
 - [ cp, "/run/mydir/generic-k8s-ibmcloud/kubelet-install-flow.sh", "/run/mydir/node.sh" ]
 - ./node.sh