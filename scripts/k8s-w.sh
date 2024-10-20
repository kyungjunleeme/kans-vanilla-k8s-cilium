#!/bin/bash
hostnamectl --static set-hostname k8s-w$1

# Config convenience
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/vagrant/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# Disable ufw & apparmor
systemctl stop ufw && systemctl disable ufw
systemctl stop apparmor && systemctl disable apparmor

# swapoff -a to disable swapping
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# local dns - hosts file
echo "192.168.10.10 k8s-s" >> /etc/hosts
echo "192.168.10.101 k8s-w1" >> /etc/hosts
echo "192.168.10.102 k8s-w2" >> /etc/hosts
echo "192.168.10.200 testpc" >> /etc/hosts

# Install packages
apt update && apt-get install -y apt-transport-https ca-certificates curl gpg

# add kubernetes repo
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# add docker-ce repo with containerd
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# packets traversing the bridge are processed by iptables for filtering
echo 1 > /proc/sys/net/ipv4/ip_forward
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# enable br_netfilter for iptables
modprobe br_netfilter
modprobe overlay
echo "br_netfilter" | tee -a /etc/modules-load.d/k8s.conf
echo "overlay" | tee -a /etc/modules-load.d/k8s.conf

# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version
apt update && apt-get install -y kubelet kubectl kubeadm containerd.io && apt-mark hold kubelet kubeadm kubectl

# containerd configure to default and cgroup managed by systemd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# avoid WARN&ERRO(default endpoints) when crictl run
cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

# ready to install for k8s
systemctl restart containerd ; systemctl enable containerd
systemctl enable --now kubelet

# Install packages
apt-get install -y bridge-utils net-tools conntrack ngrep tcpdump ipset wireguard jq tree unzip

# k8s Controlplane Join - API Server 192.168.10.10"
sed -i "s/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS=\"--node-ip=192.168.10.10$1\"/g" /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet
kubeadm join --token 123456.1234567890123456 --discovery-token-unsafe-skip-ca-verification 192.168.10.10:6443
