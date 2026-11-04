 <<-EOF
      #!/bin/bash
      set -euxo pipefail

      swapoff -a
      sed -ri '/\s+swap\s+/s/^/#/' /etc/fstab

      cat <<'MODULES' > /etc/modules-load.d/k8.conf
      br_netfilter
      MODULES

      modprobe br_netfilter

      cat <<'SYSCTL' > /etc/sysctl.d/99-kubernetes-networking.conf
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward = 1

      sysctl --system
  EOF