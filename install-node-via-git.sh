dnf install -y git
dnf install -y wget
wget https://github.com/travistolle/generic-k8s-ibmcloud/blob/main/kubelet-install-flow.sh -O /run/media/node.sh
chmod +x /run/media/node.sh
/run/media/node.sh
echo root:glisten-earshot-harbinger-frank3l | chpasswd