#!/bin/bash 
## setup root user for sshpass
echo root:bookitty | chpasswd
## Disable Swap - per kubeadm instructions
swapoff -a
## (Install Docker CE) from https://computingforgeeks.com/install-docker-and-docker-compose-on-rhel-8-centos-8/
# yum utils 
yum install -y yum-utils
# download Docker repository file to /etc/yum.repos.d/docker-ce.repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# update RPM index cache
yum makecache
# Install Docker CE
yum install docker-ce -y
# Add user root to docker group
usermod -aG docker root
# Configure Docker to use use systemd for the management of the container’s cgroups
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  'exec-opts': ['native.cgroupdriver=systemd'],
  'log-driver': 'json-file',
  'log-opts': {
    'max-size': '100m'
  },
  'storage-driver': 'overlay2'
}
EOF
# Start and enable Docker Service to start at boot
systemctl enable --now docker
## Install kubeadm and kubectl and kublet
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Install and deploy kubernetes
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
# Restart docker and enable kublet
systemctl daemon-reload
systemctl restart docker
systemctl enable --now kubelet
# These commands remove the WARNING I was getting for tc not in path when joining the node to the master 
# from https://github.com/kubernetes-sigs/kubespray/issues/4212#issuecomment-520771515
dnf provides tc
dnf install iproute-tc -y
