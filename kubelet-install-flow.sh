#!/bin/bash
#### Prepare Worker Node and Deploy Kubelet with CRI-O runtime
### Disable Swap
sudo swapoff -a
## Make the change permanent by editing the fstab file
## Edit /etc/fstab and remove the line containing swap
# RHEL 8.4 vsi image being used doesn't have swap in fstab by default
### Configure SSH
## Setup root user for sshpass
echo root:glisten-earshot-harbinger-frank3l | chpasswd
## Edit sshd_config to allow password access
#sudo sed -i '/PasswordAuthentication/ s/^#//' /etc/ssh/sshd_config
sudo sed -i '/PasswordAuthentication/ s/ no$/ yes/' /etc/ssh/sshd_config
## Restart sshd service to enable password access
sudo systemctl restart sshd
### Configure the Network
## Set hostname
export HOSTNAME=$(hostname)
export HOST_IP=$(echo `ifconfig eth0 2>/dev/null|awk '/inet / {print $2}'|sed 's/addr://'`)
printf "%s\t%s\n" "$HOST_IP" "$HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
## Install iproute-tc
sudo dnf install -y iproute-tc
## Configure iptables see bridged traffic
# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
### Open Firewall Ports
## Ensure firewalld package is installed
sudo yum install -y firewalld
## Ensure firewalld service is running
sudo systemctl enable --now firewalld
## Configure services on public zone
sudo firewall-cmd --zone=public --add-service=kube-apiserver --permanent
sudo firewall-cmd --zone=public --add-service=etcd-client --permanent
sudo firewall-cmd --zone=public --add-service=etcd-server --permanent
## Configure ports on public zone
# kubelet API
sudo firewall-cmd --zone=public --add-port=10250/tcp --permanent
# kube-scheduler
sudo firewall-cmd --zone=public --add-port=10251/tcp --permanent
# kube-controller-manager
sudo firewall-cmd --zone=public --add-port=10252/tcp --permanent
# NodePort Services
sudo firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent
# apply changes
sudo firewall-cmd --reload
### Disable SELinux
## This is NOT secure, please update SELinux to enhance security
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
### Install CRI-O
## Set version
export VERSION=1.21
## Add repos
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
# Install cri-o
sudo yum install cri-o -y
## Enable and start cri-o service
sudo systemctl enable --now cri-o
sudo systemctl start cri-o
### Install Kubernetes
## Add repos
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
## Install kubenetes packages
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
## Enable and start kubelet service
sudo systemctl enable --now kubelet
sudo systemctl start kubelet