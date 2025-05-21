#!/bin/bash

export IPADDR=$(curl -4 ifconfig.me && echo "")
export NODENAME=$(hostname -s)
export POD_CIDR="192.168.0.0/16"

sudo kubeadm init --control-plane-endpoint=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get po -n kube-system

# Make the control plane available for scheduling

kubectl taint nodes $NODENAME node-role.kubernetes.io/control-plane-

# Instsall Calico Network Plugin for Pod Networking

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Setup Kubernetes Metrics Server

kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# Setup MetalLB

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Install Helm (https://helm.sh/docs/intro/install/)

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install Cert Manager (https://cert-manager.io/docs/installation/helm/)

helm repo add jetstack https://charts.jetstack.io --force-update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --set crds.enabled=true