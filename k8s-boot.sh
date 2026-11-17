#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

K8S_VERSION="v1.37"   # set to the current stable minor (see note below)
CONTAINERD_VERSION="2.3.0"   # check github.com/containerd/containerd/releases for the latest 2.3.x / containerd version 1.x will not work with k8s v1.36+
RUNC_VERSION="1.3.0"         # check github.com/opencontainers/runc/releases for the latest

# --- Wait for outbound internet via NAT ---
until curl -s --max-time 5 https://pkgs.k8s.io >/dev/null; do
  echo "waiting for network..."
  sleep 5
done

# --- Disable swap ---
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# --- Kernel modules ---
cat <<'MODULES' > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES

modprobe overlay
modprobe br_netfilter

# --- Sysctl for pod networking ---
cat <<'SYSCTL' > /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL

sysctl --system

# --- containerd ---
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSLo /tmp/containerd.tar.gz \
  "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"
tar -C /usr/local -xzf /tmp/containerd.tar.gz

curl -fsSLo /etc/systemd/system/containerd.service \
  "https://raw.githubusercontent.com/containerd/containerd/v${CONTAINERD_VERSION}/containerd.service"

# --- runc (the binary tarball doesn't include it) ---
curl -fsSLo /tmp/runc "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
install -m 755 /tmp/runc /usr/local/sbin/runc

# --- Kubernetes packages (pinned minor version) ---
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${v1.37}/deb/Release.key" \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${v1.37}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo "BOOTSTRAP COMPLETE"
  