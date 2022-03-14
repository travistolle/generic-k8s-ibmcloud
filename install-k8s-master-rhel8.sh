#!/bin/bash
## IPs of the worker nodes (passed via API call in postman run sequence)
echo {{node_1_internal_address}} > /root/nodes
echo {{node_2_internal_address}} >> /root/nodes
echo {{node_3_internal_address}} >> /root/nodes
NODE_LIST='home/nodes'
## Disable Swap - per kubeadm instructions
swapoff -a
# Install sshpass
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum repolist
yum install sshpass -y
## (Install Docker CE) from https://computingforgeeks.com/install-docker-and-docker-compose-on-rhel-8-centos-8/
# yum utils 
yum install -y yum-utils
# download Docker repository file to /etc/yum.repos.d/docker-ce.repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# update RPM index cache
yum makecache
# Install Docker CE
yum install docker-ce -y
# Add RHEL8 default user rhel to docker group
usermod -aG docker rhel
# Configure Docker to use use systemd for the management of the container’s cgroups
mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
# Start and enable Docker Service to start at boot
systemctl enable --now docker
systemctl daemon-reload
systemctl restart docker
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
# Install and deploy kubernetes with canal CNI
wget https://docs.projectcalico.org/manifests/canal.yaml -O /root/canal.yaml
dnf provides tc -y
dnf install iproute-tc -y
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans={{master_public_address}}
## Deploy networking with canal
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f /root/canal.yaml
## Copy the admin config to the rhel user kube config
cp -i /etc/kubernetes/admin.conf /home/rhel/.kube/config
chown rhel:rhel /home/rhel/.kube -R
# SSH to workers and join them to the cluster
echo "The node error log file" > /root/node_errors
TOKEN=$(kubeadm token generate)
JOIN=$(kubeadm token create $TOKEN --print-join-command)
for NODE in $(cat /root/nodes)
do 
ssh-keyscan $NODE >> /root/.ssh/known_hosts
SSH_COMMAND="sshpass -p bookitty ssh -o StrictHostKeyChecking=no root@$NODE $JOIN"
echo $SSH_COMMAND >> /root/command_list
${SSH_COMMAND} >&2 >> /root/command_list
SSH_EXIT_STATUS="${?}"
if [[ "${SSH_EXIT_STATUS}" -ne 0 ]]
then
  EXIT_STATUS="${SSH_EXIT_STATUS}"
  echo "Execution on ${NODE} failed. $EXIT_STATUS" >&2 >>/root/node_errors
fi
cat ${EXIT_STATUS} >> /root/node_errors
done
# export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
cat /etc/kubernetes/admin.conf > /root/k8s-config
# Install HELM on the cluster
wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz -O /root/helm-v3.4.1-linux-amd64.tar.gz
tar xvf /root/helm-v3.4.1-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin
