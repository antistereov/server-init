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
