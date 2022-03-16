#!/bin/bash
#### Prepare Control Plane Node and Deploy Kubernetes with CRI-O runtime and 
#### Calico networking CNI add-on.

### Disable Swap
sudo swapoff -a
### Make the change permanent by editing the fstab file
## Edit /etc/fstab and remove the line containing swap
# RHEL 8.4 vsi image being used doesn't have swap in fstab
## Install sshpass for sending kubeadm join commands remotely to worker nodes
sudo yum install -y sshpass
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
### Create Cluster
## Set the pod network CIDR
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
## Make kubectl work for current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
## Remove the taints from this node so that it can be used as a worker node.
# kubectl taint nodes --all node-role.kubernetes.io/master-
### Install Calico Pod network CNI add-on
## Deploy the Calico Pod network
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml 
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
### Join nodes to the cluser
## Iterate list of nodes to join
echo '#!/bin/bash' > /root/command_list.sh
export TOKEN=$(kubeadm token generate)
export JOIN=$(kubeadm token create $TOKEN --print-join-command)
while IFS= read -r node; do
echo $node
ssh-keyscan $node >> /root/.ssh/known_hosts
partA="root@"
partB=$node
partC="${partA}${partB}"
partD="sshpass -p glisten-earshot-harbinger-frank3l ssh -o StrictHostKeyChecking=no "
partE="${partD} ${partC} $JOIN"
echo $partE >> /root/command_list.sh
done < /tmp/nodes
# SSH to workers and join them to the cluster
chmod +x /root/command_list.sh
/root/command_list.sh
# use the node loop for kubectl label nodes NODE node-role.kubernetes.io/worker=worker
# use the node loop to remove PasswordAuthentication on nodes