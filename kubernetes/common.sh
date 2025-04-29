#!/bin/bash
set -euo pipefail

##############################################################################
#                             INITIALIZE NODE                                #
##############################################################################

# This script can be used to initialize nodes.
# The code is taken from the following sources:
#
#  - official cri-o installation guide: https://github.com/cri-o/packaging
#  - and a blog post: https://devopscube.com/setup-kubernetes-cluster-kubeadm/
#  - official crictl installation guide: https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md

export KUBERNETES_VERSION=v1.32
export CRIO_VERSION=v1.32
export CRICTL_VERSION=v1.32.0

# Install dependencies

sudo apt install -y software-properties-common gpg curl apt-transport-https ca-certificates

############################ ENABLE BRIDGED TRAFFIC ##############################

# Enable iptables Bridged Traffic on all the Nodes

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

############################## INSTALL CRI-O ###################################

sudo apt update
sudo apt install -y software-properties-common curl

# Add the cri-o repository

curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

# Update and install the packages

sudo apt update
sudo apt install -y cri-o

# Start cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

################################# INSTALL CRICTL ###################################

curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz --output crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
sudo tar zxvf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$CRICTL_VERSION-linux-amd64.tar.gz

############################## INSTALL KUBERNETES #################################

# Add the K8s repository

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

# Update and install the packages

sudo apt install -y kubelet kubeadm kubectl

# Start kubelet

sudo systemctl daemon-reload
sudo systemctl enable kubelet --now
sudo systemctl start kubelet.service

# Add hold to the packages to prevent upgrades

sudo apt-mark hold kubelet kubeadm kubectl

# Add the node IP to KUBELET_EXTRA_ARGS

export LOCAL_IP="$(ip --json addr show eth0 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$LOCAL_IP
EOF

